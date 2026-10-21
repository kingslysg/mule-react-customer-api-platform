# Mule + React Customer API Platform

A full-stack learning sample by Kingsly Bose. The ReactJS interface sends a customer lookup through three MuleSoft APIs: Experience, Process, and mock System. The Mule APIs use RAML 1.0 contracts, APIkit routing, Mule flows, and DataWeave transformations.

> The System API returns mock data. This sample does not connect to a live Salesforce org or contain real customer records.

## Project layout

```text
reactJS-project/                              ReactJS + Vite UI
mule-projects/customer-portal-experience-api/ Experience API
mule-projects/customer-profile-process-api/  Process API
mule-projects/mock-customer-system-api/       Mock System API
deployment/                                   Build, publish, and deploy scripts
```

See the [portfolio guide](mule-react-customer-profile-integration-portfolio.docx) for architecture diagrams, project screenshots, implementation notes, and a test-scenarios table. See [deployment/README.md](deployment/README.md) for Exchange and CloudHub 2.0 release steps.

## Prerequisites

- Anypoint Studio with a compatible Mule runtime for these projects (the project was captured using Mule Runtime 4.12.x).
- Java 17 configured for the Mule projects.
- Visual Studio Code.
- Node.js and npm compatible with the Vite version installed by `npm install`.
- `curl` (included on macOS and most Linux distributions) or Postman.

## Import and run the Mule APIs in Anypoint Studio

1. Open Anypoint Studio and choose or create a workspace.
2. Import the three Mule projects from this repository. In Studio, use **File → Import → Anypoint Studio → Mule Project** (the exact label can differ slightly by Studio version). Import each project directory separately:
   - `mule-projects/mock-customer-system-api`
   - `mule-projects/customer-profile-process-api`
   - `mule-projects/customer-portal-experience-api`
3. Allow Maven dependencies to resolve. Set the projects to use Java 17 and an installed Mule runtime compatible with their POMs.
4. Run the applications in this order so downstream listeners are ready first:
   1. `Mock-Customer-System-API` — port **8084**
   2. `Customer-Profile-Process-API` — port **8082**, calls the System API at `127.0.0.1:8084`
   3. `Customer-Portal-Experience-API` — port **8083**, calls the Process API at `127.0.0.1:8082`
5. In Studio, right-click each project and choose **Run As → Mule Application**. Wait for each app's console to show it deployed without errors. Keep Studio and all three apps running while using the UI or curl.

The local API base paths are `/api`. The customer lookup resource is `POST /customer`, so the complete local URLs are:

| API | Local URL | Purpose |
| --- | --- | --- |
| Experience | `http://localhost:8083/api/customer` | UI-facing entry point; use this for the full integration test. |
| Process | `http://localhost:8082/api/customer` | Orchestrates the lookup and enriches the country name. |
| System | `http://localhost:8084/api/customer` | Returns the mock customer record. |

## Start the ReactJS UI in VS Code

1. Open VS Code and select **File → Open Folder**.
2. Choose this repository's root folder, `mule-react-customer-api-platform`.
3. Open **Terminal → New Terminal** and run:

```bash
cd reactJS-project
npm install
npm run dev
```

4. Open the Vite URL printed in the terminal, usually `http://localhost:5173`.
5. Enter a name, choose one of the supported country codes (`US`, `IN`, `CA`, or `GB`), and select **Send request**.

Vite proxies `/api` to `http://127.0.0.1:8083`, so the browser only needs the Experience API address. Keep the three Mule apps running in Studio.

## Test with curl

Run these commands from a terminal while the Mule APIs are running. The complete path is tested through the Experience API; the other two commands let you test each layer directly.

### Full path through Experience API

```bash
curl -i -X POST 'http://localhost:8083/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"IN"}'
```

Expected: **HTTP 200** and JSON containing the following values (field order and whitespace may differ):

```json
{
  "name": "Merlin",
  "countryCode": "IN",
  "countryName": "India",
  "message": "Hello, Merlin! Here is your mock customer profile for India.",
  "customer": {
    "id": "CUST-1001",
    "status": "ACTIVE",
    "plan": "Learning Demo"
  },
  "source": "System API mock data",
  "systemApi": "System API",
  "processApi": "Process API",
  "experienceApi": "Experience API"
}
```

### Test the Process API directly

```bash
curl -i -X POST 'http://localhost:8082/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"IN"}'
```

Expected: **HTTP 200** with the same customer profile fields, including `countryName: "India"` and `processApi: "Process API"`. The Process API response does not include the Experience API field.

### Test the mock System API directly

The System API accepts a country name as part of its mock request. Normally, the Process API supplies this value.

```bash
curl -i -X POST 'http://localhost:8084/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"IN","countryName":"India"}'
```

Expected: **HTTP 200** with a mock profile including `customer.id: "CUST-1001"`, `customer.status: "ACTIVE"`, `customer.plan: "Learning Demo"`, `source: "System API mock data"`, and `systemApi: "System API"`.

### Check request validation

The RAML request contract allows country codes `US`, `IN`, `CA`, and `GB`, and requires a non-empty name. Try an unsupported country code:

```bash
curl -i -X POST 'http://localhost:8083/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"ZZ"}'
```

Expected: a **4xx validation response** from the API layer. The exact response body can vary by APIkit/runtime version. Also try omitting `name` or sending an empty string; the request should be rejected by the RAML contract.

### Expected end-to-end behavior

For the supported-country request, the React response panel should show a greeting, customer ID `CUST-1001`, status `ACTIVE`, plan `Learning Demo`, and the resolved country. The Mule Studio console should show the request passing through the Experience, Process, and System APIs.

## Troubleshooting

- **Connection refused / curl cannot connect:** Confirm the relevant Mule application is deployed in Studio and listening on the port listed above. Check the Studio console for startup errors.
- **HTTP 500 from Experience API:** Confirm Process and System APIs are running, then check each app's Studio console. The Process API needs the System API on port 8084; Experience needs Process on 8082.
- **React says it cannot reach the Experience API:** Confirm all three Mule apps are running and the Vite server is using its configured `/api` proxy to port 8083. Restart `npm run dev` after changing `vite.config.js`.
- **Port already in use:** Stop the other process using that port or update the local `http.port` configuration and the corresponding downstream URLs consistently.
- **Unexpected country validation:** Use one of `US`, `IN`, `CA`, or `GB`; codes are case-sensitive in the RAML enum.

## Deploy to CloudHub 2.0

The deployment scripts are separate from the local Studio and Vite workflow. For environment setup, Connected App scopes, publishing the Mule artifacts to Exchange, CloudHub deployment order, and the optional React static-site deployment, follow [deployment/README.md](deployment/README.md). Never commit Anypoint client secrets or other deployment credentials.
