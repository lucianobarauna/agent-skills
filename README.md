# agent-skills

A personal collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills for day-to-day development workflows. Skills are shared publicly — feel free to use them in your own projects.

## Installation

Skills are installed via [`npx skills`](https://skills.sh):

```bash
npx skills install <skill-name>
```

## Structure

Each skill lives in its own folder under `skills/`:

```
skills/
└── <skill-name>/
    ├── SKILL.md          # skill definition loaded by Claude Code
    ├── README.md         # detailed documentation
    └── evals/evals.json  # test cases
```

## Standards

- **Language:** all `SKILL.md` files are written in English.
- **Documentation:** every skill has a `README.md` with a detailed explanation of what it does, how it triggers, and what it does not cover.

## Skills

| Skill | Description |
|-------|-------------|
| [pr-summary](./skills/pr-summary) | Generate a structured PR/MR description from local git commits — no API needed. Detects platform (GitHub, GitLab, Azure DevOps, Bitbucket) from remote URL. |

## Quick Start

### Create a PR summary from local commits

```bash
npx skills add lucianobarauna/pr-summary
```

Then in Claude Code, ask:
- "Summarize my commits since Monday"
- "Generate a PR description for today's work"
- "Create an MR description from commits since 2026-03-20"
