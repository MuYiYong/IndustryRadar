# IndustryRadar Release Publishing Design

## Goal

Use one GitHub Actions workflow to publish or update GitHub Releases whenever daily, weekly, or monthly Markdown reports are pushed to `main`.

## Supported report types

| Report type | File pattern | Release tag | Release title |
|---|---|---|---|
| Daily | `daily/**/*.md` with basename `YYYY-MM-DD.md` | `daily-YYYY-MM-DD` | `YYYY-MM-DD 行业简报` |
| Weekly | `weekly/**/*.md` with basename `YYYY-Www.md` | `weekly-YYYY-Www` | `YYYY-Www 行业趋势周报` |
| Monthly | `monthly/**/*.md` with basename `YYYY-MM.md` | `monthly-YYYY-MM` | `YYYY-MM 行业趋势月报` |

## Trigger behavior

The workflow runs on pushes to `main` when files under `daily/`, `weekly/`, or `monthly/` change. It also supports manual execution through `workflow_dispatch`.

For push events, the workflow calculates the files changed between the event's `before` and `after` commits. It publishes every changed Markdown report that still exists after the push. Deleted files do not delete or modify historical Releases.

For manual execution, the workflow publishes the lexicographically latest Markdown file found in each of the three report directories.

## Release behavior

The complete Markdown file is used as the Release body through `gh release create --notes-file` or `gh release edit --notes-file`.

If a Release tag does not exist, the workflow creates the Release and lets GitHub create the matching tag at the pushed commit. If the Release already exists, the workflow updates its title, body, and target commit instead of creating a duplicate.

Each successfully processed Release is marked as the latest Release. When one push changes multiple reports, the last processed report becomes the repository's latest Release.

## Safety and validation

- Workflow permission is limited to `contents: write`.
- Only files under `daily/`, `weekly/`, and `monthly/` are considered.
- Basenames must match the required date, ISO week, or month format.
- Missing or deleted files are skipped.
- Invalid filenames fail the job with a clear error.
- A concurrency group serializes Release publishing for the `main` branch.
- The workflow uses the built-in `GITHUB_TOKEN` through `GH_TOKEN`.

## Existing workflow repair

The current `.github/workflows/publish-latest-release.yml` is truncated at `tail -` and cannot run. It will be fully replaced by the unified workflow described above.
