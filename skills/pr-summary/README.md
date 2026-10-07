# pr-summary

Generate a Pull Request or Merge Request description from **local git history** and save it to disk. No remote API calls — works with private repos. The output is plain markdown, ready to paste on GitHub, GitLab, Azure DevOps or Bitbucket.

## What it does

1. **Chooses the scope** from your request: the whole branch unless you name a period, and only **your** commits (matched by your git `user.email` or `user.name`) unless you ask for everyone's.
2. **Runs `scripts/collect.sh`**, which finds the base branch on the remote, leaves out merge commits and other people's commits, tells you what was left out, and prints the file stats and the patch. Lockfile contents are skipped.
3. **Reads the change** and works out what the code does differently now.
4. **Asks for the title inputs** in one message: type, optional epic, optional tasks.
5. **Saves a markdown file** in the current directory and checks its numbers against the script's output.

## Output

```
pr-<branch-name>-summary.md      # or pr-<number>-summary.md when you give a PR/MR number or URL
```

Sections: title (`feat(EPIC-10): ...`), what changed, motivation and context, tasks (only if given), impact and risks, and a file-by-file table with line counts.

Written in English by default. Ask for another language ("em português") and the whole file, headings included, is written in it.

## Triggers

- "generate a PR description for this branch"
- "escreve a descrição do PR"
- "summarize my commits since Monday"
- "create an MR description for PR 42" or a PR/MR URL
- "gerar resumo do PR" / "resumir PR" / "descrever o MR"

## Does NOT trigger for

Code reviews, merge conflict help, commit messages, changelogs, release notes, or quick questions like "what does this PR change?" that only need an answer in chat.

## Requirements

`bash` and `git`. On Windows, use Git Bash or WSL.

## Testing

`evals/setup-fixture.sh` builds a test repo with commits by two authors, a merge from main and a lockfile change. `evals/evals.json` lists the prompts and the expected results.

```bash
bash evals/setup-fixture.sh /tmp/pr-summary-fixture
cd /tmp/pr-summary-fixture/work
```
