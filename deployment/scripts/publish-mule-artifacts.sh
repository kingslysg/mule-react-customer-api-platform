#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/deployment/artifacts/mule"

: "${ANYPOINT_BUSINESS_GROUP_ID:?Set ANYPOINT_BUSINESS_GROUP_ID to the Exchange business group ID}"
: "${ANYPOINT_CLIENT_ID:?Set ANYPOINT_CLIENT_ID from your secret store}"
: "${ANYPOINT_CLIENT_SECRET:?Set ANYPOINT_CLIENT_SECRET from your secret store}"

EXCHANGE_ORGANIZATION_ID="91f787c9-e892-42c5-b2ee-606d4d2fded7"
if [[ "$ANYPOINT_BUSINESS_GROUP_ID" != "$EXCHANGE_ORGANIZATION_ID" ]]; then
  echo "This checkout is configured for ABC ($EXCHANGE_ORGANIZATION_ID); ANYPOINT_BUSINESS_GROUP_ID does not match." >&2
  exit 1
fi

settings_file="$(mktemp "${TMPDIR:-/tmp}/mule-exchange-settings.XXXXXX")"
chmod 600 "$settings_file"
trap 'rm -f "$settings_file"' EXIT

python3 - "$settings_file" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

settings = ET.Element("settings", {"xmlns": "http://maven.apache.org/SETTINGS/1.0.0"})
servers = ET.SubElement(settings, "servers")
server = ET.SubElement(servers, "server")
ET.SubElement(server, "id").text = "anypoint-exchange-v3"
ET.SubElement(server, "username").text = "~~~Client~~~"
ET.SubElement(server, "password").text = (
    os.environ["ANYPOINT_CLIENT_ID"] + "~?~" + os.environ["ANYPOINT_CLIENT_SECRET"]
)
ET.ElementTree(settings).write(sys.argv[1], encoding="UTF-8", xml_declaration=True)
PY

publish_one() {
  local project_dir="$1"
  local artifact_id="$2"
  local project_path="$ROOT_DIR/mule-projects/$project_dir"
  local -a jars=()
  echo "Publishing $project_dir to Exchange for business group $ANYPOINT_BUSINESS_GROUP_ID..."
  (cd "$project_path" && mvn --batch-mode --no-transfer-progress -U \
    -s "$settings_file" \
    clean deploy)

  shopt -s nullglob
  jars=("$project_path"/target/"$artifact_id"-*-mule-application.jar)
  shopt -u nullglob
  if [[ "${#jars[@]}" -ne 1 ]]; then
    echo "Expected exactly one packaged Mule JAR for $artifact_id after publishing." >&2
    return 1
  fi
  mkdir -p "$ARTIFACT_DIR"
  cp "${jars[0]}" "$ARTIFACT_DIR/"
  echo "Saved the published release bundle to $ARTIFACT_DIR/${jars[0]##*/}"
}

publish_one "mock-customer-system-api" "mock-customer-system-api"
publish_one "customer-profile-process-api" "customer-profile-process-api"
publish_one "customer-portal-experience-api" "customer-portal-experience-api"

(
  cd "$ARTIFACT_DIR"
  shasum -a 256 ./*.jar > SHA256SUMS
)

echo "All three release assets were published to Exchange. Deploy them to CloudHub 2.0 in dependency order."
