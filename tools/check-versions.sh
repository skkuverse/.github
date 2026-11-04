#!/usr/bin/env bash
# Checks tools/versions.env: each entry is KEY=value, each *_VERSION an exact version, each *_SHA256_<PLATFORM> a
# lower-case sha256, no key twice, and every tool the checks download has a checksum for each platform it runs on.
# Written for bash 3.2, so it also runs with macOS's /bin/bash.
set -euo pipefail

file="$(dirname "$0")/versions.env"
status=0
fail() {
  echo "${file}: $1" >&2
  status=1
}

while IFS= read -r line || [ -n "$line" ]; do
  case $line in '' | '#'*) continue ;; esac
  key=${line%%=*}
  value=${line#*=}
  if [ "$key" = "$line" ] || ! [[ $key =~ ^[A-Z0-9_]+$ ]]; then
    fail "not KEY=value: $line"
    continue
  fi
  case $key in
    *_VERSION) [[ $value =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "$key is not an exact version: $value" ;;
    *_SHA256_*) [[ $value =~ ^[0-9a-f]{64}$ ]] || fail "$key is not a lower-case sha256: $value" ;;
    *) fail "$key is neither a *_VERSION nor a *_SHA256_<PLATFORM>" ;;
  esac
done < "$file"

required="SFW_VERSION"
for tool in ACTIONLINT ZIZMOR; do
  required="$required ${tool}_VERSION ${tool}_SHA256_LINUX_X64 ${tool}_SHA256_DARWIN_ARM64"
done
for key in $required; do
  grep -q "^${key}=" "$file" || fail "missing $key"
done

duplicates=$(grep -E '^[A-Z0-9_]+=' "$file" | cut -d= -f1 | sort | uniq -d)
[ -z "$duplicates" ] || fail "set more than once: $(echo "$duplicates" | tr '\n' ' ')"

if [ "$status" -eq 0 ]; then echo "${file}: ok"; fi
exit "$status"
