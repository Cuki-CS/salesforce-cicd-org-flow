#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/hotfix-deploy-uat.sh hotfix/INC-1234 uat-org

HOTFIX_BRANCH="${1:-}"
TARGET_ORG="${2:-uat-org}"

if [[ -z "$HOTFIX_BRANCH" ]]; then
  echo "Usage: ./scripts/hotfix-deploy-uat.sh hotfix/INC-1234 uat-org"
  exit 1
fi

echo "Checking out hotfix branch..."
git fetch origin
git checkout "$HOTFIX_BRANCH"
git pull origin "$HOTFIX_BRANCH"

echo "Generating delta from master to hotfix..."
rm -rf delta

sf sgd source delta \
  --from origin/main \
  --to HEAD \
  --output-dir delta \
  --generate-delta

if [[ ! -f delta/package/package.xml ]]; then
  echo "No deployable metadata changes found."
  exit 0
fi

EXTRA_ARGS=()

if [[ -f delta/destructiveChanges/destructiveChanges.xml ]]; then
  EXTRA_ARGS+=(--post-destructive-changes delta/destructiveChanges/destructiveChanges.xml)
fi

echo "Validating hotfix against UAT..."
sf project deploy start \
  --target-org "$TARGET_ORG" \
  --manifest delta/package/package.xml \
  --dry-run \
  --test-level RunLocalTests \
  --wait 60 \
  "${EXTRA_ARGS[@]}"

echo "Deploying hotfix to UAT..."
sf project deploy start \
  --target-org "$TARGET_ORG" \
  --manifest delta/package/package.xml \
  --test-level RunLocalTests \
  --wait 60 \
  "${EXTRA_ARGS[@]}"

echo "Hotfix deployed to UAT. Complete integration testing before merging to main."
