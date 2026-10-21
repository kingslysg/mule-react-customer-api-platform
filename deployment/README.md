# Release and deploy

This demo has three Mule applications and one React static site. The scripts build deployable artifacts, then deploy each component independently. They do not deploy anything until you run a deploy script.

## Local and CloudHub configuration

The Mule XML uses `${http.port}` and named endpoint properties. Each app's `src/main/resources/config.yaml` keeps the Studio defaults:

| App | Local listener | Local downstream |
| --- | --- | --- |
| Customer Portal Experience API | `8083` | Process API at `127.0.0.1:8082` |
| Customer Profile Process API | `8082` | System API at `127.0.0.1:8084` |
| Mock Customer System API | `8084` | None |

For CloudHub 2.0, the deployment scripts supply `http.port=8081`, HTTPS downstream connections on port `443`, and hostnames you copy from Runtime Manager. This keeps the local values intact. The deployment properties file is created in a temporary directory and removed when the command finishes. Do not store Connected App secrets in this repository.

## Build the release artifacts

From this folder:

```bash
./deployment/scripts/build-mule-artifacts.sh
./deployment/scripts/build-react-artifact.sh
```

The Mule JARs are placed in `deployment/artifacts/mule/`; the React static-site archive and checksum are placed in `deployment/artifacts/react/`. Keep those exact artifacts for promotion between environments. They are ignored by Git. If you build multiple versions, select the exact JAR with `MULE_ARTIFACT=/absolute/path/to/the-release.jar` when deploying.

The example Mule POMs now use release version `1.0.0`, not `SNAPSHOT`. Increment all three API versions together (or use your release-versioning policy) before producing a new release; avoid deploying a `SNAPSHOT` artifact to production.

## CloudHub 2.0 setup

Create an Anypoint Connected App for automation with `Design Center Developer` for Mule Maven Plugin deployments and `Exchange Contributor` (or Exchange Administrator) for publishing. Grant the scopes to the ABC business group. Put its ID and secret in your CI secret store or shell environment. Do not put the secret in a checked-in file or pass it as a Maven `-D` argument.

Set these variables in the shell or CI job that will deploy:

```bash
export ANYPOINT_ENVIRONMENT='Sandbox'       # exact environment name in Anypoint
export ANYPOINT_TARGET='Cloudhub-US-East-2' # use the target in the same region as the business group's default region
export CLOUDHUB_MULE_VERSION='4.12.0'       # choose a runtime available to your org; Java 17 is configured
export CLOUDHUB_REPLICAS='1'                # learning/sandbox value; plan HA capacity separately
export CLOUDHUB_VCORES='0.1'                # must be entitled/available in the target
export ANYPOINT_CLIENT_ID='set-from-secret-store'
# Supply ANYPOINT_CLIENT_SECRET from your secret manager; do not paste it into this file.
```

If your Anypoint control plane is not `https://anypoint.mulesoft.com`, set `ANYPOINT_URI` too. Do not assume the example target or runtime exists in your account; confirm both in Runtime Manager. The scripts require endpoint hostnames without `https://`, port, or path.

### Publish the release to Exchange

CloudHub 2.0's Mule Maven Plugin deploy flow resolves the app asset from Exchange. A local JAR by itself is not sufficient; that is why the previous attempt failed with `Failed to retrieve artifact information from Exchange` (404). The POMs use the ABC organization ID as the Maven group ID and configure the Exchange Maven Facade v3 endpoint. If you move this project to a different Anypoint organization, update the group ID and Exchange organization ID in all three POMs and in `publish-mule-artifacts.sh`. Publish once for each new release version; this also copies the published JARs into `deployment/artifacts/mule/` and refreshes their checksums:

```bash
./deployment/scripts/publish-mule-artifacts.sh
```

The script creates a temporary, permission-restricted Maven `settings.xml` using the Connected App credentials from the environment and deletes it on exit. It does not write credentials into the repository. The Connected App must have Exchange Contributor (or Administrator) access to ABC. Published release versions cannot be overwritten; increment the three POM versions before publishing changed code as another release.

### Deploy in dependency order

After publishing the release, deploy the mock System API, then the Process API, then the Experience API. The CloudHub target must be in the same region as the business group's configured default region; the previous US-East-1 error explicitly said the default was US-East-2. After deploying the System API, copy its hostname from Runtime Manager and set it before deploying Process. After Process is deployed, copy its hostname and set it before deploying Experience:

```bash
./deployment/scripts/deploy-system-api-cloudhub2.sh
export SYSTEM_API_HOST='hostname-copied-from-runtime-manager'
./deployment/scripts/deploy-process-api-cloudhub2.sh
export PROCESS_API_HOST='hostname-copied-from-runtime-manager'
./deployment/scripts/deploy-experience-api-cloudhub2.sh
```

For a private space, use the apps' internal DNS hostnames for API-to-API calls. In production, expose the Experience API to the browser, keep the Process and System APIs on internal endpoints, and apply your organization's API Manager security policies. The simple scripts deploy to the target and use host properties; configure/verify endpoint visibility in Runtime Manager for your space before exposing traffic. A mock System API returns sample data and should not be treated as a real customer-data service.

Set `DRY_RUN=true` to check a deployment script's required non-secret values and selected artifact without sending the deployment request; this does not require Connected App credentials.

The scripts send the complete property set used by this demo. MuleSoft documents that when a deployment includes `propertiesFile`, CloudHub uses that set instead of merging it with existing Runtime Manager properties. If you add more runtime properties later, add them to the generated deployment file before using the scripts.

## React static site

React is not a Mule application and should not be deployed as one of these CloudHub Mule JARs. The React build script creates a portable static bundle. The optional publish script targets a private S3 bucket behind CloudFront and requires AWS CLI credentials:

```bash
export S3_BUCKET='your-private-static-site-bucket'
export CLOUDFRONT_DISTRIBUTION_ID='your-distribution-id'
./deployment/scripts/deploy-react-s3-cloudfront.sh
```

Build the React artifact first. To promote the same build, set `REACT_ARTIFACT` to the already-built archive. The bucket or prefix must be dedicated to this site and match the CloudFront S3 origin path; the script overwrites the site's `index.html` and uploads hashed assets without deleting other objects.
Set `DRY_RUN=true` to validate the bundle and destination without uploading.

Configure the CloudFront distribution with:

1. A private S3 origin protected with Origin Access Control (OAC), used by the default `/*` behavior.
2. A `/api/*` behavior whose origin is the deployed Experience API. Forward `POST`, `Content-Type`, and any auth headers; disable caching for this behavior. This lets the UI use same-origin `/api/customer` locally and in production without a baked-in CloudHub URL or browser CORS dependency.
3. SPA fallback behavior that serves `index.html` for browser routes, if you add client-side routes.

The upload script invalidates `/` and `/index.html`; hashed Vite assets can remain cached. For production, use your normal release approval, rollback, access-control, monitoring, and secret-management controls around these scripts.
