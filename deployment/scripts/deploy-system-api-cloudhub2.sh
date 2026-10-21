#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/cloudhub2-common.sh"
deploy_cloudhub2 "mock-customer-system-api" "mock-customer-system-api" "mock-customer-system-api" system
