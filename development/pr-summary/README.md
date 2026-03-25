# pr-summary

Generate a clear, structured Pull Request or Merge Request description from **local git history** and save it to disk. No remote API authentication required — works with private repos. The output is ready to paste as a PR/MR description on GitHub, GitLab, Azure DevOps, or Bitbucket.

## What it does

1. **Detects the platform** from the remote URL (GitHub, GitLab, Azure DevOps, Bitbucket) — for formatting only, no API calls made.
2. **Parses the date range** from your request. Defaults to today if none is given.
3. **Finds the base branch** automatically (`main`, `master`, or `develop`).
4. **Collects commits** on the current branch not yet merged into the base, filtered by date range. Merge commits are excluded.
5. **Reads the diff** and understands the change — not just echoing commit messages.
6. **Saves a markdown file** in the current directory, ready to paste as a PR/MR description.

## Output format

```
pr-<branch-name>-summary.md
```

Covers: what changed, motivation & context, impact & risks, and a file-by-file breakdown with line counts.

## Triggers

- "summarize my commits since Monday"
- "generate a PR description for today's work"
- "create an MR description from commits since 2026-03-20"
- "gerar resumo do PR" / "resumir PR" / "descrever o MR"

## Does NOT trigger for

Code reviews, merge conflict help, commit messages, changelogs, or release notes.
