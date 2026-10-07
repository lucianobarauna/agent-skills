#!/usr/bin/env bash
# Collects everything pr-summary needs in one run, so the scope flags are built
# once and every number comes from git, not from the model's arithmetic.
#
# Usage: collect.sh [--since DATE] [--until DATE] [--all-authors] [--base REF] [-- PATH...]
#   --since/--until  absolute dates (YYYY-MM-DD); omit both to cover the whole branch
#   --all-authors    include everyone's commits (default: only the git user's)
#   --base REF       base ref to compare against (default: detected, remote first)
#   -- PATH...       limit the PATCH section to these paths (for large changes)
#
# Exit codes: 0 ok, 2 no branch to describe (detached HEAD or on the base branch),
#             3 no commits match, 1 usage error.

DATES=()
ALL_AUTHORS=0
BASE=""
PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --since|--until) [ -n "${2:-}" ] || { echo "ERROR: $1 needs a date" >&2; exit 1; }
                     DATES+=("$1=$2"); shift 2 ;;
    --all-authors)   ALL_AUTHORS=1; shift ;;
    --base)          BASE="${2:-}"; shift 2 ;;
    --)              shift; PATHS=("$@"); break ;;
    *) echo "ERROR: unknown option $1" >&2; exit 1 ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "ERROR: not inside a git repository" >&2; exit 1; }

CURRENT=$(git branch --show-current)
if [ -z "$CURRENT" ]; then
  echo "STOP: detached HEAD. Switch to the feature branch first."; exit 2
fi

# Remote refs first: a stale local main would make merged commits look new.
if [ -z "$BASE" ]; then
  BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
fi
if [ -z "$BASE" ]; then
  for c in origin/main origin/master origin/develop main master develop; do
    if [ "$c" != "origin/$CURRENT" ] && [ "$c" != "$CURRENT" ] \
       && git rev-parse --verify --quiet "$c" >/dev/null; then
      BASE=$c; break
    fi
  done
fi
[ -n "$BASE" ] || { echo "STOP: no base branch found. Ask the user which branch the PR targets, then pass --base."; exit 2; }
if [ "${BASE#origin/}" = "$CURRENT" ]; then
  echo "STOP: the current branch ($CURRENT) is the base branch. Switch to the feature branch first."; exit 2
fi

NAME=$(git config user.name)
EMAIL=$(git config user.email)
AUTHOR=()
if [ "$ALL_AUTHORS" = 0 ]; then
  [ -n "$EMAIL" ] && AUTHOR+=(--author="$EMAIL")
  [ -n "$NAME" ]  && AUTHOR+=(--author="$NAME")
fi

# ${X[@]+"${X[@]}"} expands an empty array safely on bash 3.2 (macOS).
log() { git log "$BASE..HEAD" --no-merges ${DATES[@]+"${DATES[@]}"} "$@"; }
mine() { log ${AUTHOR[@]+"${AUTHOR[@]}"} "$@"; }

echo "== SCOPE"
echo "branch: $CURRENT"
echo "base: $BASE (show as: ${BASE#origin/})"
if [ ${#AUTHOR[@]} -gt 0 ]; then echo "author: $NAME <$EMAIL>"; else echo "author: everyone"; fi
if [ ${#DATES[@]} -gt 0 ]; then echo "period: ${DATES[*]}"; else echo "period: whole branch"; fi

echo; echo "== COMMITS"
COMMITS=$(mine --format="%h %s (%an, %ad)" --date=short)
if [ -z "$COMMITS" ]; then
  echo "none"
  echo; echo "== RECENT COMMITS ON THE BRANCH (to fix the period or author)"
  git log "$BASE..HEAD" --no-merges --format="%h %an %ad %s" --date=short -10
  exit 3
fi
echo "$COMMITS"
echo "count: $(echo "$COMMITS" | wc -l | tr -d ' ')"

echo; echo "== NOT INCLUDED (tell the user)"
if [ ${#AUTHOR[@]} -gt 0 ]; then
  SELECTED=$(mine --format="%H")
  OTHERS=$(log --format="%H %an" | grep -vF "$SELECTED" | cut -d' ' -f2- | sort | uniq -c | sed 's/^ *//')
  [ -n "$OTHERS" ] && echo "$OTHERS" | sed 's/^\([0-9]*\) \(.*\)$/other author: \1 commit(s) by \2/'
fi
if [ ${#DATES[@]} -gt 0 ]; then
  ALL_MINE=$(git log "$BASE..HEAD" --no-merges ${AUTHOR[@]+"${AUTHOR[@]}"} --format="%h" | wc -l | tr -d ' ')
  IN_RANGE=$(echo "$COMMITS" | wc -l | tr -d ' ')
  OUTSIDE=$((ALL_MINE - IN_RANGE))
  [ "$OUTSIDE" -gt 0 ] && echo "outside the period: $OUTSIDE of the selected author's commit(s)"
fi

echo; echo "== FILES (sum over the selected commits; binary files show as -)"
STATS=$(mine --numstat --format="" | awk -F'\t' 'NF==3 {
    f=$3; if (!(f in seen)) { seen[f]=1; order[++n]=f }
    if ($1=="-") bin[f]=1; else { a[f]+=$1; d[f]+=$2 }
  }
  END {
    for (i=1; i<=n; i++) { f=order[i]
      if (bin[f]) printf "%s\t-\t-\n", f; else printf "%s\t+%d\t-%d\n", f, a[f], d[f]
      ta+=a[f]; td+=d[f] }
    printf "TOTAL: %d files +%d -%d\n", n, ta, td
  }')
echo "$STATS"
CHANGED=$(echo "$STATS" | tail -1 | awk '{gsub(/[+-]/,""); print $4+$5}')

echo; echo "== PATCH (lockfiles left out)"
if [ ${#PATHS[@]} -eq 0 ] && [ "$CHANGED" -gt 5000 ]; then
  echo "SKIPPED: $CHANGED changed lines. Re-run with -- <paths> for the most impactful files."
  exit 0
fi
[ ${#PATHS[@]} -eq 0 ] && PATHS=(.)
mine -p --format="commit %h %s" -- "${PATHS[@]}" ':!*package-lock.json' ':!*pnpm-lock.yaml' ':!*.lock'
