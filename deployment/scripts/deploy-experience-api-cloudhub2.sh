#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cloudhub2-common.sh"
deploy_cloudhub2 "customer-portal-experience-api" "customer-portal-experience-api" "customer-portal-experience-api" experience
