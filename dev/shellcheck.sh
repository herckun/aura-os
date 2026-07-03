#!/usr/bin/env bash
set -euo pipefail

# Shellcheck validation script
# Finds all .sh files in core/bash/, features/, dev/ (excluding scripts/)
# and runs shellcheck on each, reporting violations grouped by file.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR" || exit 1

# Check shellcheck availability
if ! command -v shellcheck &>/dev/null; then
  echo "WARNING: shellcheck is not installed. Please install it to validate scripts."
  echo "  Install: pacman -S shellcheck  (or)  apt install shellcheck"
  exit 0
fi

# Find all .sh files in target directories, excluding scripts/ and this script itself
SELF="dev/shellcheck.sh"
mapfile -t files < <(
  find core/bash/ features/ dev/ \
    -name '*.sh' \
    -not -path 'scripts/*' \
    -not -path "$SELF" \
    -type f | sort
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No .sh files found to check."
  exit 0
fi

echo "=== Shellcheck Validation ==="
echo "Checking ${#files[@]} files..."
echo ""

failures=0
passed=0

for file in "${files[@]}"; do
  output=$(shellcheck -f gcc "$file" 2>&1) || true

  if [[ -z "$output" ]]; then
    passed=$((passed + 1))
  else
    failures=$((failures + 1))
    echo "--- $file ---"
    echo "$output"
    echo ""
  fi
done

echo "=== Summary ==="
echo "  Passed: $passed"
echo "  Failed: $failures"
echo "  Total:  ${#files[@]}"

if [[ $failures -gt 0 ]]; then
  exit 1
fi

exit 0
