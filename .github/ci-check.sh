#!/usr/bin/env bash
# One suite of the reduced CI of the sandbox (.github/workflows/ci.yml): it takes CI_SECONDS
# (default 20), then passes, unless a tracked file of the commit holds, anywhere in a line (in a
# comment of a Java file, which still compiles), one of:
#   CI-FAIL: <suite>               the suite fails
#   CI-FAIL-WITH: <path> <suite>   the suite fails once <path> exists too: a commit that only
#                                  fails on top of another (after a rebase, for example)
# Suites: build (which also runs compile-check.sh), unitTests, integrationTests, acceptanceTests.
#
# Usage: .github/ci-check.sh <suite>   (in the checkout of the commit)
set -euo pipefail
suite=${1:?usage: ci-check.sh <suite>}
# the build: the code must "compile" (compile-check.sh)
[ "$suite" != build ] || bash "$(dirname "$0")/compile-check.sh"
sleep "${CI_SECONDS:-20}"
failed=()
while IFS=$'\t' read -r file kind path want; do
  if [ "$kind" = fail ] && [ "$path" = "$suite" ]; then
    failed+=("$file asks $suite to fail")
  elif [ "$kind" = with ] && [ "$want" = "$suite" ] && [ -e "$path" ]; then
    failed+=("$file asks $suite to fail with $path, which exists")
  fi
done < <(git grep -I -n -E 'CI-FAIL(-WITH)?: ' -- . ':!.github/*' \
  | sed -nE 's/^([^:]+:[0-9]+):.*CI-FAIL-WITH: ([^[:space:]]+) ([A-Za-z]+).*/\1\twith\t\2\t\3/p
             t
             s/^([^:]+:[0-9]+):.*CI-FAIL: ([A-Za-z]+).*/\1\tfail\t\2\t/p' || true)
if [ ${#failed[@]} -gt 0 ]; then
  printf '%s\n' "${failed[@]}"
  exit 1
fi
echo "$suite passed"
