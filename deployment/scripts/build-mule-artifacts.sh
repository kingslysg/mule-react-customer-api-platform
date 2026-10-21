#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MULE_ROOT="$ROOT_DIR/mule-projects"
ARTIFACT_DIR="$ROOT_DIR/deployment/artifacts/mule"

mkdir -p "$ARTIFACT_DIR"

build_one() {
  local project_dir="$1"
  local artifact_id="$2"
  local project_path="$MULE_ROOT/$project_dir"
  local matches

  echo "Building $artifact_id ..."
  (cd "$project_path" && mvn --batch-mode --no-transfer-progress clean verify)

  # Require exactly one deployable Mule application artifact.
  shopt -s nullglob
  matches=("$project_path"/target/"$artifact_id"-*-mule-application.jar)
  shopt -u nullglob
  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "Expected one Mule application JAR for $artifact_id, found ${#matches[@]}" >&2
    return 1
  fi

  cp "${matches[0]}" "$ARTIFACT_DIR/"
  echo "Saved ${matches[0]##*/} to $ARTIFACT_DIR"
}

# Build downstream APIs first; deployment order should follow the same order.
build_one "mock-customer-system-api" "mock-customer-system-api"
build_one "customer-profile-process-api" "customer-profile-process-api"
build_one "customer-portal-experience-api" "customer-portal-experience-api"

(
  cd "$ARTIFACT_DIR"
  shasum -a 256 ./*.jar > SHA256SUMS
)

echo "Mule release artifacts and checksums are ready in: $ARTIFACT_DIR"
