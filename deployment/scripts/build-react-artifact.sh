#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$ROOT_DIR/reactJS-project"
ARTIFACT_DIR="$ROOT_DIR/deployment/artifacts/react"

mkdir -p "$ARTIFACT_DIR"
cd "$PROJECT_DIR"

npm ci
npm run build

version="$(node -p "JSON.parse(require('fs').readFileSync('package.json', 'utf8')).version")"
bundle="$ARTIFACT_DIR/customer-profile-react-ui-$version.tar.gz"
tar -czf "$bundle" -C "$PROJECT_DIR/dist" .
(cd "$ARTIFACT_DIR" && shasum -a 256 "${bundle##*/}" > "${bundle##*/}.sha256")

echo "React static-site bundle: $bundle"
echo "The bundle uses same-origin /api requests. Configure the CDN /api/* behavior to route to the Experience API."
