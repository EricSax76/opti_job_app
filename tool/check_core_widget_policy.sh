#!/usr/bin/env bash
set -eo pipefail

# Architecture guardrail:
# Enforce direct core import usage in every widget outside lib/core.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

readonly CORE_IMPORT_PATTERN="^import[[:space:]]+['\"][^'\"]*(package:opti_job_app/core/|(\\.\\./)+core/)"

contains_core_import() {
  local file="$1"

  if command -v rg >/dev/null 2>&1; then
    rg -q --hidden -S "$CORE_IMPORT_PATTERN" "$file"
  else
    grep -qE "$CORE_IMPORT_PATTERN" "$file"
  fi
}

collect_widget_files() {
  local files=()

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      [[ "$file" == lib/* ]] || continue
      [[ "$file" == *"/widgets/"* ]] || continue
      [[ "$file" == *.dart ]] || continue
      [[ "$file" == lib/core/* ]] && continue
      [[ -f "$file" ]] || continue
      files+=("$file")
    done < <(git ls-files '*.dart')
  else
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      file="${file#./}"
      [[ "$file" == lib/* ]] || continue
      [[ "$file" == *"/widgets/"* ]] || continue
      [[ "$file" == *.dart ]] || continue
      [[ "$file" == lib/core/* ]] && continue
      files+=("$file")
    done < <(find . -type f -name '*.dart')
  fi

  printf '%s\n' "${files[@]}" | sort
}

WIDGET_FILES=()
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  WIDGET_FILES+=("$file")
done < <(collect_widget_files)

if [[ "${#WIDGET_FILES[@]}" -eq 0 ]]; then
  echo "Core widget policy check skipped: no widget files found."
  exit 0
fi

violations=()
for file in "${WIDGET_FILES[@]}"; do
  if ! contains_core_import "$file"; then
    violations+=("$file")
  fi
done

if [[ "${#violations[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: widgets without direct core import found."
  echo
  echo "Rule: files matching lib/**/widgets/*.dart (except lib/core/**) must import core directly."
  echo
  echo "Violations (${#violations[@]}):"
  printf '  - %s\n' "${violations[@]}"
  exit 1
fi

echo "Core widget policy check passed."
echo "Checked ${#WIDGET_FILES[@]} widgets. No missing direct core imports."
