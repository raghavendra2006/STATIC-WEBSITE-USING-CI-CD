#!/usr/bin/env bash
set -euo pipefail

# Ensure variables are set
if [ -z "${PROD_DISTRIBUTION_ID:-}" ] || [ -z "${SSM_PARAMETER_NAME:-}" ]; then
  echo "Error: PROD_DISTRIBUTION_ID and SSM_PARAMETER_NAME environment variables must be defined."
  exit 1
fi

echo "=== Initiating Zero-Downtime Rollback ==="

# 1. Determine current active and rollback target colors
echo "Querying SSM parameter store for active production color..."
active_color=$(aws ssm get-parameter --name "$SSM_PARAMETER_NAME" --query "Parameter.Value" --output text)
echo "Current active color: $active_color"

if [ "$active_color" = "blue" ]; then
  rollback_color="green"
  target_origin_id="prod-green-origin"
elif [ "$active_color" = "green" ]; then
  rollback_color="blue"
  target_origin_id="prod-blue-origin"
else
  echo "Error: Invalid active color returned from SSM: $active_color"
  exit 1
fi

echo "Rolling back to previous environment color: $rollback_color"
echo "Target CloudFront Origin ID: $target_origin_id"

# 2. Switch CloudFront origin back
echo "Fetching current CloudFront distribution config..."
aws cloudfront get-distribution-config --id "$PROD_DISTRIBUTION_ID" > dist_config_raw.json

etag=$(jq -r '.ETag' dist_config_raw.json)
jq '.DistributionConfig' dist_config_raw.json > dist_config.json

echo "Modifying distribution config target origin to: $target_origin_id..."
jq --arg origin "$target_origin_id" '.DefaultCacheBehavior.TargetOriginId = $origin' dist_config.json > updated_config.json

echo "Updating CloudFront distribution routing..."
aws cloudfront update-distribution \
  --id "$PROD_DISTRIBUTION_ID" \
  --distribution-config file://updated_config.json \
  --if-match "$etag" > /dev/null

echo "✔ CloudFront distribution updated to point back to $rollback_color origin."

# 3. Invalidate CloudFront cache
echo "Creating CloudFront cache invalidation..."
invalidation_id=$(aws cloudfront create-invalidation \
  --distribution-id "$PROD_DISTRIBUTION_ID" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "Invalidation created with ID: $invalidation_id"

# 4. Update SSM active color tracker back
echo "Updating SSM parameter active color to: $rollback_color..."
aws ssm put-parameter \
  --name "$SSM_PARAMETER_NAME" \
  --value "$rollback_color" \
  --type "String" \
  --overwrite

echo "✔ SSM parameter store updated."

# 5. Print rollback success details
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat <<EOF >> "$GITHUB_STEP_SUMMARY"
## ↩️ Rollback Executed Successfully

| Step | Detail |
|---|---|
| **New Active Target** | \`$rollback_color\` |
| **Previous Target** | \`$active_color\` |
| **Status** | CDN routing redirected and cache invalidation created |
EOF
fi

echo "=== Rollback to $rollback_color environment completed successfully! ==="
