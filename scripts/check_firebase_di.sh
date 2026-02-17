#!/bin/bash

# Check for implicit Firebase fallbacks
FALLBACKS=$(grep -r "\?\?\s*Firebase.*\.instance" lib/modules)
if [ -n "$FALLBACKS" ]; then
  echo "❌ Error: Found implicit Firebase fallbacks (?? Firebase*.instance) in lib/modules:"
  echo "$FALLBACKS"
  exit 1
fi

# Check for direct Firebase instance access in data layer
INSTANCES=$(grep -r "Firebase.*\.instance" lib/modules)
if [ -n "$INSTANCES" ]; then
   echo "❌ Error: Found direct Firebase instance access (Firebase*.instance) in lib/modules:"
   echo "$INSTANCES"
   exit 1
fi

echo "✅ Firebase DI Check Passed"
exit 0
