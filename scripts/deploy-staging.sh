#!/usr/bin/env bash
set -euo pipefail

# Ensure variables are set
if [ -z "${STAGING_BUCKET_NAME:-}" ] || [ -z "${STAGING_DISTRIBUTION_ID:-}" ] || [ -z "${STAGING_URL:-}" ]; then
  echo "Error: STAGING_BUCKET_NAME, STAGING_DISTRIBUTION_ID, and STAGING_URL environment variables must be defined."
  exit 1
fi

echo "=== Deploying to Staging ==="
echo "Target S3 Bucket: $STAGING_BUCKET_NAME"
echo "CloudFront Distribution: $STAGING_DISTRIBUTION_ID"
echo "Staging URL: $STAGING_URL"

# Sync dist/ directory to Staging S3 Bucket
echo "Syncing build output to staging bucket..."
aws s3 sync dist/ "s3://$STAGING_BUCKET_NAME" --delete --no-progress

# Invalidate CloudFront Distribution Cache
echo "Creating CloudFront cache invalidation..."
invalidation_id=$(aws cloudfront create-invalidation \
  --distribution-id "$STAGING_DISTRIBUTION_ID" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "Invalidation created with ID: $invalidation_id"

# Post-deploy smoke check
echo "Waiting 5 seconds for cache invalidation propagation..."
sleep 5

echo "Executing staging post-deploy smoke check..."
max_attempts=5
attempt=1
success=false

while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts: Curling $STAGING_URL"
  # Fetch status code and content length, passing silent flag and ignoring TLS/SSL cert issues if any (staging domains might be generic)
  status_code=$(curl -o /dev/null -s -w "%{http_code}" -k "$STAGING_URL")
  
  if [ "$status_code" -eq 200 ]; then
    echo "✔ Smoke check successful! Received HTTP 200 OK."
    success=true
    break
  else
    echo "⚠ Received HTTP status $status_code. Retrying in 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
  fi
done

if [ "$success" = false ]; then
  echo "❌ Error: Smoke check failed after $max_attempts attempts."
  exit 1
fi

echo "=== Staging Deployment Completed Successfully ==="
