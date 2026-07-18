#!/usr/bin/env bash
set -euo pipefail

release_metadata() {
  local file=$1 dir stem
  dir=${file%%/*}
  stem=$(basename "$file" .md)

  case "$dir" in
    daily)
      [[ "$stem" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1
      printf 'daily-%s\t%s 行业简报\n' "$stem" "$stem"
      ;;
    weekly)
      [[ "$stem" =~ ^[0-9]{4}-W[0-9]{2}$ ]] || return 1
      printf 'weekly-%s\t%s 行业趋势周报\n' "$stem" "$stem"
      ;;
    monthly)
      [[ "$stem" =~ ^[0-9]{4}-[0-9]{2}$ ]] || return 1
      printf 'monthly-%s\t%s 行业趋势月报\n' "$stem" "$stem"
      ;;
    *) return 1 ;;
  esac
}

collect_reports() {
  local event=$1 before=$2 after=$3 dir latest

  if [[ "$event" == "push" ]]; then
    if [[ -z "$before" || "$before" =~ ^0+$ ]]; then
      git diff-tree --no-commit-id --name-only --diff-filter=AM -r "$after" -- daily weekly monthly
    else
      git diff --name-only --diff-filter=AM "$before" "$after" -- daily weekly monthly
    fi | grep -E '^(daily|weekly|monthly)/.*\.md$' || true
    return
  fi

  for dir in daily weekly monthly; do
    [[ -d "$dir" ]] || continue
    latest=$(find "$dir" -type f -name '*.md' | sort | tail -n 1)
    [[ -n "$latest" ]] && printf '%s\n' "$latest"
  done
}

publish_report() {
  local file=$1 sha=$2 metadata tag title

  [[ -s "$file" ]] || {
    echo "::warning file=$file::Report is missing or empty; skipping"
    return
  }

  if ! metadata=$(release_metadata "$file"); then
    echo "::warning file=$file::Unsupported report filename; skipping"
    return
  fi

  IFS=$'\t' read -r tag title <<< "$metadata"

  if gh release view "$tag" >/dev/null 2>&1; then
    git tag -f "$tag" "$sha"
    git push origin "refs/tags/$tag" --force
    gh release edit "$tag" --title "$title" --notes-file "$file" --target "$sha"
    echo "Updated release: $title ($tag)"
  else
    gh release create "$tag" --title "$title" --notes-file "$file" --target "$sha"
    echo "Created release: $title ($tag)"
  fi
}

main() {
  local event=${EVENT_NAME:-${GITHUB_EVENT_NAME:-}}
  local before=${BEFORE_SHA:-}
  local after=${AFTER_SHA:-${GITHUB_SHA:-}}
  local file
  local -a reports=()

  [[ -n "$event" ]] || { echo "EVENT_NAME is required" >&2; exit 1; }
  [[ -n "$after" ]] || { echo "AFTER_SHA or GITHUB_SHA is required" >&2; exit 1; }

  mapfile -t reports < <(collect_reports "$event" "$before" "$after" | sort -u)

  if (( ${#reports[@]} == 0 )); then
    echo "No report files to publish"
    return
  fi

  for file in "${reports[@]}"; do
    publish_report "$file" "$after"
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
