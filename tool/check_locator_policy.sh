#!/usr/bin/env bash
set -euo pipefail

# Architecture guardrail:
# Block GetIt/locator usage outside approved composition roots.
# This check scans all tracked Dart files in the repository.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

readonly PATTERN='GetIt|get_it|locator'

# Allowed locations for locator usage.
readonly ALLOWED_PREFIXES=(
  "lib/bootstrap/"
)
readonly ALLOWED_FILES=(
  "lib/main.dart"
  "lib/core/router/app_router.dart"
)

is_allowed_path() {
  local file="$1"
  local prefix
  local allowed_file

  for prefix in "${ALLOWED_PREFIXES[@]}"; do
    if [[ "$file" == "$prefix"* ]]; then
      return 0
    fi
  done

  for allowed_file in "${ALLOWED_FILES[@]}"; do
    if [[ "$file" == "$allowed_file" ]]; then
      return 0
    fi
  done

  return 1
}

collect_matches() {
  local files=()
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      [[ -f "$file" ]] || continue
      files+=("$file")
    done < <(git ls-files '*.dart')
  else
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      files+=("$file")
    done < <(find . -type f -name '*.dart')
  fi

  if [[ "${#files[@]}" -eq 0 ]]; then
    return 0
  fi

  if command -v rg >/dev/null 2>&1; then
    rg -n --hidden -S "$PATTERN" "${files[@]}" || true
  else
    grep -nHE "$PATTERN" "${files[@]}" || true
  fi
}

MATCHES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  MATCHES+=("$line")
done < <(collect_matches)

if [[ "${#MATCHES[@]}" -eq 0 ]]; then
  echo "No locator/get_it references found in tracked Dart files."
  exit 0
fi

violations=()

for match in "${MATCHES[@]}"; do
  file="${match%%:*}"
  if ! is_allowed_path "$file"; then
    violations+=("$match")
  fi
done

if [[ "${#violations[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: locator/get_it usage outside allowlist."
  echo
  echo "Allowed prefixes:"
  printf '  - %s\n' "${ALLOWED_PREFIXES[@]}"
  echo "Allowed files:"
  printf '  - %s\n' "${ALLOWED_FILES[@]}"
  echo
  echo "Disallowed matches:"
  printf '  - %s\n' "${violations[@]}"
  exit 1
fi

echo "Locator policy check passed."
echo "Matches found only in approved locations: ${#MATCHES[@]}"
