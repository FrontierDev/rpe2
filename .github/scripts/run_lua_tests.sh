#!/usr/bin/env bash
# Run each regression test in an isolated Lua 5.1 process.  Keep going after
# failures so a single stale fixture cannot hide the rest of the suite.
set -uo pipefail

lua_bin="${LUA_BIN:-lua5.1}"
test_root="${1:-tests}"

if ! command -v "$lua_bin" >/dev/null 2>&1; then
  echo "Unable to find Lua interpreter: $lua_bin" >&2
  exit 2
fi

mapfile -t tests < <(find "$test_root" -maxdepth 1 -type f -name '*Test.lua' -print | LC_ALL=C sort)
if ((${#tests[@]} == 0)); then
  echo "No Lua regression tests found under $test_root" >&2
  exit 2
fi

failures=()
for test in "${tests[@]}"; do
  name="${test#${test_root}/}"
  if "$lua_bin" "$test"; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    failures+=("$name")
  fi
done

echo
echo "${#failures[@]} / ${#tests[@]} tests failed"
if ((${#failures[@]} > 0)); then
  printf -- '- %s\n' "${failures[@]}"
  exit 1
fi
