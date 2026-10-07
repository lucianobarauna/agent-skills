#!/usr/bin/env bash
# Builds a test repo for the pr-summary evals: a feature branch with commits by
# the user and by a coworker, a merge from main in the middle, an old commit
# outside a recent date range, and a lockfile change.
#
# Usage: bash setup-fixture.sh <empty-dir>
# The repo's git user is "Dev Tester <dev@example.com>", so the author filter
# keeps Dev's commits and reports Ana's as ignored.
set -euo pipefail

DIR=${1:?usage: setup-fixture.sh <empty-dir>}
mkdir -p "$DIR" && cd "$DIR"

git init -q --bare origin.git
git init -q -b main work && cd work
git config user.name "Dev Tester"
git config user.email "dev@example.com"
git remote add origin ../origin.git

# commit <author name> <author email> <days ago> <message>
commit() {
  local when
  when=$(date -v-"$3"d +%Y-%m-%dT10:00:00 2>/dev/null || date -d "$3 days ago" +%Y-%m-%dT10:00:00)
  git add -A
  GIT_AUTHOR_NAME="$1" GIT_AUTHOR_EMAIL="$2" GIT_AUTHOR_DATE="$when" \
  GIT_COMMITTER_NAME="$1" GIT_COMMITTER_EMAIL="$2" GIT_COMMITTER_DATE="$when" \
    git commit -q -m "$4"
}

mkdir -p src
echo 'export const greet = (n) => `Hi ${n}`;' > src/greet.js
echo '{"name":"app","version":"1.0.0"}' > package.json
commit "Dev Tester" "dev@example.com" 20 "chore: initial project"
git push -q -u origin main
git remote set-head origin main

git switch -q -c feat/login
cat > src/auth.js <<'EOF'
export function login(user, pass) {
  if (!user || !pass) throw new Error('missing credentials');
  return fetch('/api/login', { method: 'POST', body: JSON.stringify({ user, pass }) });
}
EOF
commit "Dev Tester" "dev@example.com" 10 "feat: add login request"

# Work that lands on main while the branch is open, merged in later.
git switch -q main
echo '# Deploy guide' > DEPLOY.md
commit "Carlos Main" "carlos@example.com" 6 "docs: add deploy guide"
git push -q origin main
git switch -q feat/login
GIT_COMMITTER_DATE=$(date -v-5d +%Y-%m-%dT10:00:00 2>/dev/null || date -d "5 days ago" +%Y-%m-%dT10:00:00) \
  git merge -q --no-edit main

cat > src/session.js <<'EOF'
export const SESSION_TTL_MS = 30 * 60 * 1000;
export function isExpired(startedAt) { return Date.now() - startedAt > SESSION_TTL_MS; }
EOF
commit "Ana Souza" "ana@example.com" 3 "feat: add session expiry helper"

cat > src/auth.js <<'EOF'
import { isExpired } from './session.js';
export function login(user, pass) {
  if (!user || !pass) throw new Error('missing credentials');
  return fetch('/api/login', { method: 'POST', body: JSON.stringify({ user, pass }) });
}
export function logout() { localStorage.removeItem('token'); }
export { isExpired };
EOF
printf '{"lockfileVersion":3,"packages":{"":{"name":"app"}}}\n%.0s' {1..50} > package-lock.json
commit "Dev Tester" "dev@example.com" 0 "feat: add logout and lockfile"

echo "Fixture ready: $DIR/work (branch feat/login, base origin/main)"
