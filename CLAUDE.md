# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of Claude Code skills — reusable prompt-driven agents that extend Claude Code's capabilities. Each skill lives in its own subdirectory under `skills/` and is installed via `npx skills add lucianobarauna/agent-skills --skill <skill-name>`.

Skills have no build process, no runtime dependencies, and no package manager. Everything is plain Markdown and JSON, plus small bash scripts (a skill may ship `scripts/` it runs; evals may ship a fixture builder).

## Skill Structure

Each skill directory (e.g. `skills/pr-summary/`) contains:
- `SKILL.md` — The skill definition loaded by Claude Code at runtime. This is the core artifact.
- `README.md` — User-facing documentation.
- `evals/evals.json` — Test cases used to validate skill behavior (plus an optional fixture script that builds a test repo).

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
- `expectations` — LLM-judged checks on the output (typically checking that specific findings are present)

When adding or modifying a skill, update the evals to cover the new/changed behavior.

## Skills in This Repo

- **pr-summary** (`skills/pr-summary/`) — Generates a PR/MR description from the user's own commits on the current branch (local git only, no API calls). Covers the whole branch by default, or a date range when asked. Saves `pr-<branch-name>-summary.md` in the current directory.
