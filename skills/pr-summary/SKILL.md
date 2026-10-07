---
name: pr-summary
description: >
  Generates a Pull Request or Merge Request description from local git commits and saves it
  as a markdown file ready to paste on GitHub, GitLab, Azure DevOps or Bitbucket. Makes no
  API calls, so it works with private repos. Use when the user wants a PR/MR description
  written up: "generate a PR description", "create an MR description for this branch",
  "summarize my commits since Monday", "gerar resumo do PR", "resumir PR", "descrever o MR",
  "escreve a descrição do PR", or when they give a PR/MR number or URL.
  Covers what changed, why, the risks and a suggested title.
  Do NOT use for code reviews, merge conflict help, commit messages, changelogs, release
  notes, or quick questions about what a PR changes that only need an answer in chat.
---

# PR Summary

Builds a PR/MR description from **local git history** and saves it to disk. The description must cover the user's own commits on this branch and nothing else. `scripts/collect.sh` does the git work so that code merged in from the base branch and other people's commits stay out, and every number comes from git rather than from mental arithmetic.

Copy this checklist and tick it off:

```text
PR summary progress:
- [ ] 1 Scope chosen from the request
- [ ] 2 collect.sh run, NOT INCLUDED relayed to the user
- [ ] 3 Change understood from the PATCH
- [ ] 4 Title inputs asked
- [ ] 5 File written
- [ ] 6 File checked against TOTAL
```

## Step 1 — Choose the scope

From the request, decide two things:

- **Period.** By default none: a PR description covers everything the branch will merge. Only when the user names one ("since Monday", "today", "from March 20 to 25"), convert it to absolute dates from today's date.
- **Authors.** By default only the user's commits. Everyone's only when the user asks for it.

## Step 2 — Run the collector

Run it from the repository, do not read it (`${CLAUDE_SKILL_DIR}` is this skill's folder; outside Claude Code, use the folder this SKILL.md was read from):

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/collect.sh [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--all-authors] [-- <paths>]
```

It finds the base branch (the remote ref, since a stale local `main` makes merged commits look new), filters by the user's git email or name, leaves merge commits out, and prints `SCOPE`, `COMMITS`, `NOT INCLUDED`, `FILES` with a `TOTAL` line, and `PATCH`.

- **Output starts with `STOP:`** (exit 2): tell the user the reason it gives and stop. There is no PR to describe from here.
- **`COMMITS` is `none`** (exit 3): show the recent commits it lists, ask the user to adjust the period or author, and return to Step 1.
- **`NOT INCLUDED` has lines:** tell the user in one line, by name (e.g. "Ignored 1 commit by Ana Souza; 1 of your commits is outside the period"). The PR page will show those commits, so a silent filter would leave the reviewer looking at code the description never mentions.
- **`PATCH` says `SKIPPED`:** the change is too large to read whole. Re-run with `-- <paths>` for the most impactful files from `FILES`, and say in the summary that it covers a large change.

Done when you have the full output, including the PATCH.

## Step 3 — Understand the change

Read the whole `PATCH` before writing anything. Commit messages give the intent; the patch shows what really changed. Use both, and state no cause the patch does not show. Point out what a reviewer must not miss: dependency, schema, config or environment variable changes, removed behaviour, and code the selected commits use from commits left out (another author, outside the period), since the PR merges that code too. When there are many commits, group them by area instead of listing each one.

Done when you can say in plain words what the code does differently now.

## Step 4 — Ask for the title inputs

In a single message, ask for:

- `<type>` — e.g. feat, fix, chore, refactor
- `<epic>` — optional epic code, e.g. `EPIC-10`
- `<tasks>` — optional links or codes of the tasks/tickets this PR covers

The title is `<type>(<epic>): <description>`, or `<type>: <description>` without an epic. Tasks never go in the title, even without an epic: they belong to the Tasks section. `<description>` sums up "What changed" in the imperative, starting lowercase, without a trailing period, ideally in 72 characters or fewer.

## Step 5 — Write the file

**Name:** `pr-<NUMBER>-summary.md` when the user gave a PR/MR number or URL (take the number from the path, e.g. `/pull/42`, `/merge_requests/42`, `/pullrequest/42`); otherwise `pr-<branch>-summary.md`, with `/` and spaces replaced by `-`. Save it in the current working directory. If the file already exists, ask before overwriting it.

**Language:** English, unless the user asks for another language. Then translate all the text — headings, bold labels, table header and footer — so the file does not mix languages; keep code, paths and the title prefix (`feat(EPIC-10):`) as they are, but translate the title's description.

Use this exact structure:

```markdown
# <title from Step 4>

**Branch:** `<current-branch>` → `<base, as SCOPE shows it>`
**Commits:** <N> by <git user.name>[; not included: <M> by <other names>]
**Period:** <start_date> – <end_date>
**Files changed:** <N> (+<additions> / -<deletions>)

---

## What changed

<2–4 sentences on what the code does differently now. Not a list of commit messages or file names.>

## Motivation and context

<Why the change was made: the problem it solves or the feature it adds.>

## Tasks

<only when the user gave tasks; format below>

## Impact and risks

<Breaking changes, migrations, env vars, schema or config changes, areas that need attention.
"No breaking changes identified." when that is genuinely the case.>

## Files changed

| File | Changes |
|------|---------|
| `path/to/file.ts` | +42 / -10 — what changed here |

---

*Generated by pr-summary skill on <date>.*
```

- **Period:** the requested range, ending today when the user gave no end. Omit the line when there are no date flags.
- **Tasks:** a URL becomes a link with the task code as text (`- [PROJ-123](https://jira.example.com/browse/PROJ-123)`); a plain code stays plain text (`- PROJ-456`). Omit the section, heading included, when the user gave no tasks.
- **Files changed:** copy the numbers from `FILES` and `TOTAL`. They add up the selected commits, so a line changed in two commits counts twice.

Keep every section short: a reviewer should get through it in 60 seconds.

## Step 6 — Check the file

Compare the saved file with the collector's output: the `**Files changed:**` line must match `TOTAL`, the table must list every file in `FILES` with the same numbers, and `**Commits:**` must match the `COMMITS` count and `NOT INCLUDED`. If anything differs, fix the file and check again.
