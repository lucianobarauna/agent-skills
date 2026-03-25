# review-pr

A pre-PR code review focused on best practices, performance, and security for **JavaScript / TypeScript** projects. Acts as a senior engineer reviewing your code before it hits the PR — direct, actionable, and always explaining the "why" behind each finding.

## What it does

1. **Identifies changed files** against `main` using `git diff --name-only main`.
2. **Reviews each file** across three dimensions:
   - **Best practices & readability** — naming, typing, DRY, SOLID principles
   - **Performance & optimization** — unnecessary re-renders, expensive loops, duplicate calls, lazy loading
   - **Security & bugs** — exposed sensitive data, XSS, injection, `debugger` in production, `window.open` without `noopener`, undefined values in URLs or queries
3. **Scores each dimension** (X/10) with specific observations and before/after code examples.
4. **Explains every finding** in plain language for junior developers — no jargon, always answering "why does this matter in practice."
5. **Concludes with:**
   - An overall PR score (weighted, prioritizing security)
   - The top 3 critical issues to fix before merging
   - A clear merge signal: ✅ Ready to open / ⚠️ Fix first

## What it does NOT cover

Formatting and code style (spaces, semicolons) — that's the linter's job.

## Output language

The review is always written in **English**, regardless of the language used in the request.

## Triggers

- `/review-pr`
- "review my code" / "review my code before the PR"
- "check this before I push"
- "audit for security"
- "give feedback on this"
- "is this ready to merge"
- "second set of eyes"
- "pre-PR review" / "check this branch before merging"
- Any request to review code before opening a pull request or delivering a feature

## Does NOT trigger for

General coding help, debugging, writing tests, explaining concepts, or architecture discussions.
