# IndustryRadar Release Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken daily-only workflow with one validated GitHub Actions workflow that creates or updates daily, weekly, and monthly Releases from complete Markdown report files.

**Architecture:** A single workflow listens for report-file pushes and manual runs. A Bash discovery step produces a normalized report list, and a publishing step validates each filename, derives the tag and title, then uses GitHub CLI to create or edit the corresponding Release.

**Tech Stack:** GitHub Actions, Bash, GitHub CLI (`gh`), Git, Markdown.

## Global Constraints

- Repository: `MuYiYong/IndustryRadar`.
- Branch: `main`.
- Daily tags and titles: `daily-YYYY-MM-DD`, `YYYY-MM-DD 行业简报`.
- Weekly tags and titles: `weekly-YYYY-Www`, `YYYY-Www 行业趋势周报`.
- Monthly tags and titles: `monthly-YYYY-MM`, `YYYY-MM 行业趋势月报`.
- Release body must exactly use the corresponding Markdown file contents.
- Existing Releases must be updated, not duplicated.
- Deleted reports must not delete historical Releases.
- Use only the built-in `GITHUB_TOKEN` with `contents: write`.

---

### Task 1: Replace the broken unified Release workflow

**Files:**
- Modify: `.github/workflows/publish-latest-release.yml`

**Interfaces:**
- Consumes: push event fields `github.event.before`, `github.sha`, and report files under `daily/`, `weekly/`, and `monthly/`.
- Produces: GitHub Releases with deterministic tags, titles, complete Markdown bodies, and targets set to the triggering commit.

- [ ] **Step 1: Write the complete workflow to a temporary file**

Use this exact workflow content:

```yaml
name: Publish Industry Report Releases

on:
  push:
    branches:
      - main
    paths:
      - "daily/**/*.md"
      - "weekly/**/*.md"
      - "monthly/**/*.md"
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: publish-industry-report-releases-${{ github.ref }}
  cancel-in-progress: false

jobs:
  release:
    name: Create or update report releases
    runs-on: ubuntu-latest
    env:
      GH_TOKEN: ${{ github.token }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Find reports to publish
        id: reports
        shell: bash
        run: |
          set -euo pipefail

          output_file="${RUNNER_TEMP}/reports.txt"
          : > "$output_file"

          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            for directory in daily weekly monthly; do
              if [[ -d "$directory" ]]; then
                latest_report=$(find "$directory" -type f -name '*.md' | sort | tail -n 1)
                if [[ -n "$latest_report" ]]; then
                  printf '%s\n' "$latest_report" >> "$output_file"
                fi
              fi
            done
          else
            before="${{ github.event.before }}"
            after="${{ github.sha }}"

            if [[ "$before" == "0000000000000000000000000000000000000000" ]]; then
              git show --pretty='' --name-only "$after" > "${RUNNER_TEMP}/changed-files.txt"
            elif git cat-file -e "${before}^{commit}" 2>/dev/null; then
              git diff --name-only "$before" "$after" > "${RUNNER_TEMP}/changed-files.txt"
            else
              git show --pretty='' --name-only "$after" > "${RUNNER_TEMP}/changed-files.txt"
            fi

            grep -E '^(daily|weekly|monthly)/.*\.md$' "${RUNNER_TEMP}/changed-files.txt" \
              | sort -u \
              | while IFS= read -r report; do
                  if [[ -f "$report" ]]; then
                    printf '%s\n' "$report" >> "$output_file"
                  fi
                done
          fi

          if [[ ! -s "$output_file" ]]; then
            echo "No report files need publishing."
            echo "has_reports=false" >> "$GITHUB_OUTPUT"
            exit 0
          fi

          echo "Reports selected for publishing:"
          cat "$output_file"
          echo "has_reports=true" >> "$GITHUB_OUTPUT"
          echo "report_file=$output_file" >> "$GITHUB_OUTPUT"

      - name: Create or update releases
        if: steps.reports.outputs.has_reports == 'true'
        shell: bash
        run: |
          set -euo pipefail

          while IFS= read -r report; do
            directory="${report%%/*}"
            filename="$(basename "$report")"
            identifier="${filename%.md}"

            case "$directory" in
              daily)
                if [[ ! "$identifier" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                  echo "Invalid daily report filename: $report" >&2
                  exit 1
                fi
                tag="daily-${identifier}"
                title="${identifier} 行业简报"
                ;;
              weekly)
                if [[ ! "$identifier" =~ ^[0-9]{4}-W[0-9]{2}$ ]]; then
                  echo "Invalid weekly report filename: $report" >&2
                  exit 1
                fi
                tag="weekly-${identifier}"
                title="${identifier} 行业趋势周报"
                ;;
              monthly)
                if [[ ! "$identifier" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
                  echo "Invalid monthly report filename: $report" >&2
                  exit 1
                fi
                tag="monthly-${identifier}"
                title="${identifier} 行业趋势月报"
                ;;
              *)
                echo "Unsupported report directory: $directory" >&2
                exit 1
                ;;
            esac

            echo "Publishing $report as $tag"

            if gh release view "$tag" >/dev/null 2>&1; then
              gh release edit "$tag" \
                --title "$title" \
                --notes-file "$report" \
                --target "$GITHUB_SHA" \
                --latest
            else
              gh release create "$tag" \
                --title "$title" \
                --notes-file "$report" \
                --target "$GITHUB_SHA" \
                --latest
            fi
          done < "${{ steps.reports.outputs.report_file }}"
```

- [ ] **Step 2: Validate YAML parsing**

Run:

```bash
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/publish-latest-release.yml"); puts "YAML OK"'
```

Expected output:

```text
YAML OK
```

- [ ] **Step 3: Validate both embedded Bash scripts**

Extract each `run: |` block into temporary shell files without changing indentation-sensitive content, then run:

```bash
bash -n /tmp/find-reports.sh
bash -n /tmp/publish-releases.sh
```

Expected output: no output and exit code `0` for both commands.

- [ ] **Step 4: Commit the workflow replacement**

```bash
git add .github/workflows/publish-latest-release.yml
git commit -m "ci: publish daily weekly and monthly releases"
```

### Task 2: Verify the committed workflow

**Files:**
- Read: `.github/workflows/publish-latest-release.yml`

**Interfaces:**
- Consumes: committed workflow from Task 1.
- Produces: evidence that the repository contains the complete workflow and that the broken `tail -` fragment is gone.

- [ ] **Step 1: Fetch the committed workflow**

```bash
git show HEAD:.github/workflows/publish-latest-release.yml
```

Expected: the complete YAML shown in Task 1, including both `gh release create` and `gh release edit` commands.

- [ ] **Step 2: Confirm required triggers and naming rules**

```bash
grep -E 'daily/\*\*/\*\.md|weekly/\*\*/\*\.md|monthly/\*\*/\*\.md|daily-\$\{identifier\}|weekly-\$\{identifier\}|monthly-\$\{identifier\}' .github/workflows/publish-latest-release.yml
```

Expected: matches for all three path filters and all three tag prefixes.

- [ ] **Step 3: Confirm the old truncation is absent**

```bash
if grep -Fxq '          REPORT=$(find daily -type f -name '\''*.md'\'' | sort | tail -' .github/workflows/publish-latest-release.yml; then
  echo "Broken workflow fragment still exists" >&2
  exit 1
fi
```

Expected: exit code `0` with no output.
