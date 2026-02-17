#!/bin/bash

# Define the forbidden pattern
PATTERN="package:get_it/get_it.dart"

# Define allowed files/directories (regex compatible with grep -E)
ALLOWED="lib/bootstrap/|lib/main.dart"

# Find files containing the pattern
VIOLATIONS=$(grep -r "$PATTERN" lib | grep -vE "$ALLOWED")

if [ -n "$VIOLATIONS" ]; then
  echo "❌ Architecture Check Failed: GetIt usage found outside allowed boundaries:"
  echo "$VIOLATIONS"
  exit 1
else
  echo "✅ Architecture Check Passed: No illegal GetIt usage found."
  exit 0
fi
