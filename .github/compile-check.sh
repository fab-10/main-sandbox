#!/usr/bin/env bash
# The "compilation" of the dummy code of the sandbox, which has no build: fails, with errors in
# the format of javac, when a Java file still has conflict markers, or uses a constant
# SandboxLimits.<NAME> that SandboxLimits does not declare. The build suite of the CI runs it, and
# so can any tool that compiles the code.
#
# Usage: .github/compile-check.sh   (in the checkout of the commit)
set -euo pipefail
errors=0
declared=$(git ls-files -z '*/SandboxLimits.java' | xargs -0 -r sed -nE 's/.*static final [A-Za-z]+ ([A-Z_][A-Z0-9_]*) =.*/\1/p')
while IFS= read -r f; do
  [ -n "$f" ] || continue
  while IFS=: read -r n _; do
    echo "$f:$n: error: conflict marker"; errors=$((errors + 1))
  done < <(grep -nE '^(<<<<<<<|=======|>>>>>>>)( |$)' "$f" || true)
  while IFS=: read -r n name; do
    if ! grep -qxF "$name" <<<"$declared"; then
      echo "$f:$n: error: cannot find symbol: variable $name in SandboxLimits"; errors=$((errors + 1))
    fi
  done < <(grep -noE 'SandboxLimits\.[A-Z_][A-Z0-9_]*' "$f" | sed -E 's/SandboxLimits\.//' || true)
done < <(git ls-files '*.java')
if [ "$errors" -gt 0 ]; then echo "$errors errors"; exit 1; fi
echo "compiled"
