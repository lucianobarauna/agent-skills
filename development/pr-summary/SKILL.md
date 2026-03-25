---
name: pr-summary
description: >
  Use this skill whenever the user wants to document, summarize, or write up a Pull Request
  or Merge Request based on their local git commits — no remote API access needed.
  Triggers for: "summarize my commits since Monday", "generate a PR description for today's
  work", "create an MR description from commits since 2026-03-20", "gerar resumo do PR",
  "resumir PR", "o que mudou nesse PR", "descrever o MR", as well as when the user gives a
  PR/MR number or URL as a reference point. Detects the platform (GitHub, GitLab, Azure
  DevOps, Bitbucket) from the remote URL to format the output correctly — but makes no API
  calls. Produces a structured markdown file covering what changed, the motivation, and the
  risks, ready to paste as a PR/MR description.
  Do NOT trigger for code reviews, merge conflict help, commit messages, changelogs, or
  release notes — only when the user explicitly wants a saved PR/MR summary or description.
---

# PR Summary Skill

Generate a clear, structured markdown summary of a Pull Request or Merge Request from **local git history** and save it to disk. No remote API authentication required — works with private repos. The output is ready to paste as a PR/MR description on GitHub, GitLab, Azure DevOps, or Bitbucket.

---

## Step 1 — Detect the platform

Parse the remote URL to identify the platform. This is for formatting only — no API calls are made.

```bash
git remote get-url origin
```

| Remote URL contains              | Platform      |
|----------------------------------|---------------|
| `github.com`                     | GitHub        |
| `gitlab.com` or `gitlab.`        | GitLab        |
| `dev.azure.com` / `visualstudio` | Azure DevOps  |
| `bitbucket.org`                  | Bitbucket     |

If no remote is configured or the platform is unrecognized, default to GitHub format (widely compatible) and note it in the output.

---

## Step 2 — Determine the date range

Parse the user's request for a date range:

- **Start date given** (e.g., "since Monday", "since 2026-03-20", "from last week"): use that as the start date. Translate relative expressions to absolute dates using today's date.
- **No date given**: default to today only (start = beginning of today).
- **End date given**: use it. Otherwise, end = now.

---

## Step 3 — Find the base branch

Identify which branch this work will be merged into:

```bash
# Try the default remote branch
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If that fails, check for `main`, `master`, or `develop` in order, **skipping the current branch**:

```bash
git branch -r | grep -E 'origin/(main|master|develop)' | head -3
```

Fall back to `main` if nothing is found.

---

## Step 4 — Collect commits and diff

Get the commits on the **current branch** that are not yet in the base branch, filtered by the date range. Exclude merge commits — they add noise without substance.

```bash
# Current branch
CURRENT=$(git branch --show-current)

# Commits on this branch not in base, filtered by date (no merge commits)
git log <base_branch>..HEAD \
  --since="<start_date>" --until="<end_date>" \
  --no-merges \
  --format="%h %s (%an, %ad)" --date=short
```

If no commits are returned, tell the user and show the 5 most recent non-merge commits on the branch so they can adjust the range:

```bash
git log <base_branch>..HEAD --no-merges --oneline -5
```

Once you have commits, find the oldest one in the range and generate the diff for **only those commits** — not the entire branch history:

```bash
# Find the oldest commit in the filtered range
OLDEST=$(git log <base_branch>..HEAD --since="<start_date>" --until="<end_date>" \
  --no-merges --format="%H" | tail -1)

# Diff from just before that commit to HEAD (covers exactly the work in scope)
git diff ${OLDEST}^..HEAD --stat
git diff ${OLDEST}^..HEAD
```

This ensures the diff matches the commits being described — especially important when the date range is shorter than the full branch history.

---

## Step 5 — Analyze and write the summary

Read the commits and diff carefully. Your job is to *understand* the change, not just echo commit messages or list files. Think about:

- **What** changed, in plain language
- **Why** — infer from commit messages and code patterns
- **What might need attention** — dependency changes, schema changes, config changes, removed functionality

Commit messages signal the author's intent; the diff reveals the reality. Use both.

---

## Step 6 — Save the output

Determine the filename:
- If the user gave a PR/MR number: `pr-<NUMBER>-summary.md`
- Otherwise: use the current branch name, sanitized — replace `/` and spaces with `-`: `pr-<branch-name>-summary.md`

Save in the current working directory using this exact template:

```markdown
# PR: <Title — infer from commits and branch name>

**Platform:** <GitHub | GitLab | Azure DevOps | Bitbucket>
**Branch:** `<current-branch>` → `<base-branch>`
**Commits:** <N commits in range>
**Period:** <start_date> – <end_date>
**Files changed:** <N> (+<additions> / -<deletions>)

---

## What changed

<2–4 sentences describing the substance of the change in plain language.
Focus on what the code does differently now. Avoid just listing commit messages or file names.>

## Motivation and context

<Why was this change made? What problem does it solve or what feature does it add?
Draw from commit messages and patterns in the diff.>

## Impact and risks

<What could this affect? Are there breaking changes, migration steps, environment
variable changes, schema changes, or areas that need attention?>

## Files changed

| File | Changes |
|------|---------|
| `path/to/file.ts` | +42 / -10 — brief note on what changed here |
| `path/to/other.ts` | +5 / -3 — brief note |

---

*Generated by pr-summary skill on <date>.*
```

Keep each section concise. "Impact and risks" can say "No breaking changes identified." if that's genuinely the case — don't pad it. The goal is a summary a reviewer can read in 60 seconds.

---

## Edge cases

- **No commits in date range**: Inform the user and show the 5 most recent non-merge commits on the branch as a hint.
- **Current branch IS the base branch** (e.g., user is on `main`): Warn them — suggest switching to their feature branch or integration branch first.
- **Very large diff (>500 files or >5000 lines)**: Focus "What changed" on the most impactful files; note the total size.
- **No remote configured**: Skip platform detection, use GitHub format, note it in the output.
- **Many commits over multiple days**: Group the summary by logical area (feature, bugfix, refactor) rather than listing every commit individually.
