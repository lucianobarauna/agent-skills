# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of Claude Code skills — reusable prompt-driven agents that extend Claude Code's capabilities. Each skill lives in its own subdirectory under `development/` and is installed via `npx skills install <skill-name>`.

Skills have no build process, no runtime dependencies, and no package manager. Everything is plain Markdown and JSON.

## Skill Structure

Each skill directory (e.g. `development/pr-summary/`) contains:
- `SKILL.md` — The skill definition loaded by Claude Code at runtime. This is the core artifact.
- `README.md` — User-facing documentation.
- `evals/evals.json` — Test cases used to validate skill behavior.

## Authoring Skills

### SKILL.md

A `SKILL.md` defines:
1. **Trigger conditions** — exact phrases and patterns that activate the skill
2. **Non-trigger conditions** — what explicitly should NOT activate it
3. **Step-by-step execution instructions** — what Claude does when the skill runs
4. **Output format** — expected structure of the skill's response or saved artifact

Keep trigger descriptions precise to avoid false activations. Non-trigger conditions are as important as triggers.

### evals/evals.json

Evals validate that the skill detects the right things and behaves correctly. Each entry has:
- `prompt` — the user message that activates the skill
- `assertions` — LLM-judged checks on the output (typically checking that specific findings are present)

When adding or modifying a skill, update the evals to cover the new/changed behavior.

## Skills in This Repo

- **pr-summary** (`development/pr-summary/`) — Generates a structured PR/MR description from local git history. Detects the platform (GitHub, GitLab, Azure DevOps, Bitbucket) from the remote URL. Saves output as `pr-<branch-name>-summary.md`. Does not make API calls.
- **review-pr** (`development/review-pr/`) — Pre-merge code review for JS/TS: best practices, performance, and security. Scores each dimension 1–10, outputs before/after examples, and ends with a merge signal (✅ Ready or ⚠️ Fix first). Output is always in English.
