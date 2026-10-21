#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/deployment/artifacts/react"

: "${S3_BUCKET:?Set S3_BUCKET to the private S3 bucket behind your CloudFront distribution}"
: "${CLOUDFRONT_DISTRIBUTION_ID:?Set CLOUDFRONT_DISTRIBUTION_ID}"

bundle="${REACT_ARTIFACT:-}"
if [[ -z "$bundle" ]]; then
  shopt -s nullglob
  bundles=("$ARTIFACT_DIR"/customer-profile-react-ui-*.tar.gz)
  shopt -u nullglob
  if [[ "${#bundles[@]}" -ne 1 ]]; then
    echo "Expected one React bundle in $ARTIFACT_DIR. Run build-react-artifact.sh or set REACT_ARTIFACT." >&2
    exit 1
  fi
  bundle="${bundles[0]}"
fi
[[ "$bundle" = /* ]] || bundle="$ROOT_DIR/$bundle"
if [[ ! -f "$bundle" ]]; then
  echo "React artifact not found: $bundle" >&2
  exit 1
fi

if [[ "${DRY_RUN:-false}" == "true" ]]; then
  echo "DRY_RUN=true: validated bundle $bundle for bucket s3://$S3_BUCKET and CloudFront distribution $CLOUDFRONT_DISTRIBUTION_ID; skipped upload."
  exit 0
fi

command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required." >&2; exit 1; }
site_dir="$(mktemp -d "${TMPDIR:-/tmp}/customer-profile-ui.XXXXXX")"
trap 'rm -rf "$site_dir"' EXIT
tar -xzf "$bundle" -C "$site_dir"

echo "Publishing $bundle to private S3 bucket s3://$S3_BUCKET"
aws s3 sync "$site_dir" "s3://$S3_BUCKET" \
  --exclude index.html \
  --cache-control 'public,max-age=31536000,immutable'
aws s3 cp "$site_dir/index.html" "s3://$S3_BUCKET/index.html" \
  --content-type 'text/html; charset=utf-8' \
  --cache-control 'no-cache,no-store,must-revalidate'
aws cloudfront create-invalidation \
  --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
  --paths '/' '/index.html'

echo "Published. Confirm the CloudFront distribution has /api/* routed to the Experience API and the default behavior uses the private S3 origin."
