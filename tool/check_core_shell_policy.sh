#!/usr/bin/env bash
set -eo pipefail

# Architecture guardrail (Phase 6):
# Enforce CoreShell adoption in already-migrated areas and keep
# exception traceability explicit via allowlist IDs.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

readonly SCAFFOLD_PATTERN='\bScaffold\s*\('
readonly EXCEPTION_REGISTRY='docs/fase_6_5_registro_excepciones_shell_core.md'

# Incremental enforcement scope: areas migrated in Phase 6.3/6.4.
readonly ENFORCED_PREFIXES=(
  "lib/auth/ui/pages/"
  "lib/home/pages/"
  "lib/modules/job_offers/ui/pages/"
  "lib/modules/candidates/ui/widgets/"
)
readonly ENFORCED_FILES=(
  "lib/modules/companies/ui/pages/company_dashboard_screen.dart"
  "lib/modules/companies/ui/widgets/company_interviews_tab.dart"
)

# Approved exception allowlist (Phase 6.5).
readonly EXCEPTION_IDS=(
  "shell-ex-001"
  "shell-ex-002"
)
readonly EXCEPTION_SCAFFOLD_FILES=(
  "lib/modules/interviews/ui/widgets/chat/interview_chat_view.dart"
  "lib/features/video_curriculum/view/video_playback_screen.dart"
)
readonly EXCEPTION_TAG_FILES=(
  "lib/core/router/app_router.dart"
  "lib/features/video_curriculum/view/video_curriculum_playback_helpers.dart"
)

is_enforced_file() {
  local file="$1"
  local prefix
  local enforced_file

  for prefix in "${ENFORCED_PREFIXES[@]}"; do
    if [[ "$file" == "$prefix"* ]]; then
      return 0
    fi
  done

  for enforced_file in "${ENFORCED_FILES[@]}"; do
    if [[ "$file" == "$enforced_file" ]]; then
      return 0
    fi
  done

  return 1
}

is_exception_scaffold_file() {
  local file="$1"
  local exception_file

  for exception_file in "${EXCEPTION_SCAFFOLD_FILES[@]}"; do
    if [[ "$file" == "$exception_file" ]]; then
      return 0
    fi
  done

  return 1
}

collect_enforced_files() {
  local files=()

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      [[ -f "$file" ]] || continue
      if is_enforced_file "$file"; then
        files+=("$file")
      fi
    done < <(git ls-files '*.dart')
  else
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      file="${file#./}"
      if is_enforced_file "$file"; then
        files+=("$file")
      fi
    done < <(find . -type f -name '*.dart')
  fi

  printf '%s\n' "${files[@]}"
}

collect_scaffold_matches() {
  local files=("$@")

  [[ "${#files[@]}" -eq 0 ]] && return 0

  if command -v rg >/dev/null 2>&1; then
    rg -n --hidden -S "$SCAFFOLD_PATTERN" "${files[@]}" || true
  else
    grep -nHE "$SCAFFOLD_PATTERN" "${files[@]}" || true
  fi
}

contains_pattern() {
  local pattern="$1"
  local file="$2"

  if command -v rg >/dev/null 2>&1; then
    rg -q --hidden -S "$pattern" "$file"
  else
    grep -qE "$pattern" "$file"
  fi
}

ENFORCED_FILE_LIST=()
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  ENFORCED_FILE_LIST+=("$file")
done < <(collect_enforced_files)

if [[ "${#ENFORCED_FILE_LIST[@]}" -eq 0 ]]; then
  echo "CoreShell policy check skipped: no enforced files found."
  exit 0
fi

MATCHES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  MATCHES+=("$line")
done < <(collect_scaffold_matches "${ENFORCED_FILE_LIST[@]}")

violations=()
for match in "${MATCHES[@]}"; do
  file="${match%%:*}"
  if ! is_exception_scaffold_file "$file"; then
    violations+=("$match")
  fi
done

if [[ "${#violations[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: Scaffold usage found in CoreShell-enforced areas."
  echo
  echo "Enforced prefixes:"
  printf '  - %s\n' "${ENFORCED_PREFIXES[@]}"
  echo "Enforced files:"
  printf '  - %s\n' "${ENFORCED_FILES[@]}"
  echo
  echo "Violations:"
  printf '  - %s\n' "${violations[@]}"
  exit 1
fi

if [[ ! -f "$EXCEPTION_REGISTRY" ]]; then
  echo "Architecture policy violation: exception registry not found: $EXCEPTION_REGISTRY"
  exit 1
fi

registry_missing=()
tag_missing=()
scaffold_missing=()

for i in "${!EXCEPTION_IDS[@]}"; do
  id="${EXCEPTION_IDS[$i]}"
  scaffold_file="${EXCEPTION_SCAFFOLD_FILES[$i]}"
  tag_file="${EXCEPTION_TAG_FILES[$i]}"

  if ! contains_pattern "$id" "$EXCEPTION_REGISTRY"; then
    registry_missing+=("$id")
  fi

  if [[ ! -f "$tag_file" ]] || ! contains_pattern "$id" "$tag_file"; then
    tag_missing+=("$id => $tag_file")
  fi

  if [[ ! -f "$scaffold_file" ]]; then
    scaffold_missing+=("$id => missing file $scaffold_file")
  elif ! contains_pattern "$SCAFFOLD_PATTERN" "$scaffold_file"; then
    scaffold_missing+=("$id => no Scaffold found in $scaffold_file")
  fi
done

if [[ "${#registry_missing[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: exception IDs missing from registry."
  printf '  - %s\n' "${registry_missing[@]}"
  exit 1
fi

if [[ "${#tag_missing[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: exception tags missing in code."
  printf '  - %s\n' "${tag_missing[@]}"
  exit 1
fi

if [[ "${#scaffold_missing[@]}" -gt 0 ]]; then
  echo "Architecture policy violation: exception scaffold sources are out of sync."
  printf '  - %s\n' "${scaffold_missing[@]}"
  exit 1
fi

echo "CoreShell policy check passed."
echo "No Scaffold usage found in enforced areas."
echo "Exception allowlist traceability validated (${#EXCEPTION_IDS[@]} exceptions)."
