#!/usr/bin/env bash

require_value() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Required environment variable is not set: $name" >&2
    return 1
  fi
}

require_host_only() {
  local name="$1"
  require_value "$name"
  local value="${!name}"
  if [[ "$value" == *"://"* || "$value" == */* || "$value" == *" "* ]]; then
    echo "$name must be a hostname only (no scheme, port, path, or spaces)." >&2
    return 1
  fi
}

deploy_cloudhub2() {
  local app_dir="$1"
  local artifact_id="$2"
  local runtime_app_name="$3"
  local api_kind="$4"
  local script_dir root_dir jar_path props_file

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  root_dir="$(cd "$script_dir/../../.." && pwd)"
  app_dir="$root_dir/mule-projects/$app_dir"

  require_value ANYPOINT_ENVIRONMENT
  require_value ANYPOINT_BUSINESS_GROUP_ID
  require_value ANYPOINT_TARGET
  require_value CLOUDHUB_MULE_VERSION
  require_value CLOUDHUB_VCORES
  require_value CLOUDHUB_REPLICAS
  if [[ "${DRY_RUN:-false}" != "true" ]]; then
    require_value ANYPOINT_CLIENT_ID
    require_value ANYPOINT_CLIENT_SECRET
  fi

  if [[ ! "$CLOUDHUB_REPLICAS" =~ ^[0-9]+$ ]] || [[ "$CLOUDHUB_REPLICAS" -lt 1 ]]; then
    echo "CLOUDHUB_REPLICAS must be a positive whole number." >&2
    return 1
  fi
  case "$CLOUDHUB_VCORES" in
    0.1|0.2|0.5|1|1.5|2|2.5|3|3.5|4) ;;
    *) echo "CLOUDHUB_VCORES must be one of the CloudHub 2.0 supported values." >&2; return 1 ;;
  esac

  jar_path="${MULE_ARTIFACT:-}"
  if [[ -z "$jar_path" ]]; then
    local -a jars=()
    shopt -s nullglob
    jars=("$root_dir"/deployment/artifacts/mule/"$artifact_id"-*-mule-application.jar)
    shopt -u nullglob
    if [[ "${#jars[@]}" -ne 1 ]]; then
    echo "Expected exactly one JAR for $artifact_id in deployment/artifacts/mule. Run build-mule-artifacts.sh or set MULE_ARTIFACT to the exact release JAR." >&2
      return 1
    fi
    jar_path="${jars[0]}"
  fi
  [[ "$jar_path" = /* ]] || jar_path="$root_dir/$jar_path"
  if [[ ! -f "$jar_path" ]]; then
    echo "Mule artifact not found: $jar_path" >&2
    return 1
  fi

  props_file="$(mktemp "${TMPDIR:-/tmp}/mule-cloudhub2-properties.XXXXXX")"
  MULE_CLOUDHUB_PROPERTIES_FILE="$props_file"
  trap 'rm -f "$MULE_CLOUDHUB_PROPERTIES_FILE"' EXIT
  {
    printf 'http.port=8081\n'
    case "$api_kind" in
      experience)
        require_host_only PROCESS_API_HOST
        printf 'process.api.protocol=HTTPS\nprocess.api.host=%s\nprocess.api.port=443\n' "$PROCESS_API_HOST"
        ;;
      process)
        require_host_only SYSTEM_API_HOST
        printf 'system.api.protocol=HTTPS\nsystem.api.host=%s\nsystem.api.port=443\n' "$SYSTEM_API_HOST"
        ;;
      system)
        ;;
      *)
        echo "Unknown API kind: $api_kind" >&2
        return 1
        ;;
    esac
  } > "$props_file"

  echo "Deploying $runtime_app_name to CloudHub 2.0 in environment '$ANYPOINT_ENVIRONMENT' / target '$ANYPOINT_TARGET'."
  echo "Local artifact: $jar_path"
  echo "CloudHub 2.0 resolves the published Exchange asset by this POM's groupId, artifactId, and version. Publish the release first with ./deployment/scripts/publish-mule-artifacts.sh."
  echo "Deployment properties will replace the app's Runtime Manager property set. This script supplies the complete set used by this demo."

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "DRY_RUN=true: skipped the Maven deployment."
    return 0
  fi

  (cd "$app_dir" && mvn --batch-mode --no-transfer-progress -Pcloudhub2 mule:deploy \
    -Dmule.artifact="$jar_path" \
    -Danypoint.uri="${ANYPOINT_URI:-https://anypoint.mulesoft.com}" \
    -Danypoint.environment="$ANYPOINT_ENVIRONMENT" \
    -Danypoint.businessGroupId="$ANYPOINT_BUSINESS_GROUP_ID" \
    -Dcloudhub.target="$ANYPOINT_TARGET" \
    -Dcloudhub.muleVersion="$CLOUDHUB_MULE_VERSION" \
    -Dcloudhub.applicationName="$runtime_app_name" \
    -Dcloudhub.replicas="$CLOUDHUB_REPLICAS" \
    -Dcloudhub.vCores="$CLOUDHUB_VCORES" \
    -Dcloudhub.propertiesFile="$props_file") || {
      echo "CloudHub deployment failed. If the response says Exchange returned 404, publish the matching release to Exchange first; the local JAR alone is not enough for Mule Maven Plugin deployment to CloudHub 2.0." >&2
      return 1
    }
}
