**PORTFOLIO PROJECT**

# Customer Profile Integration Platform

*A portfolio sample by Kingsly Bose*

A full-stack sample that connects a ReactJS customer experience to a MuleSoft API-led architecture. Requests move through Experience, Process, and mock System APIs, with RAML contracts, APIkit routing, Mule flows, and DataWeave transformations.

**ReactJS · RAML 1.0 · APIkit · Mule Flows · DataWeave**

![ReactJS customer profile portal demonstrating the API-led request and sample customer response](portfolio-assets/01-customer-profile-portal.png)

Portfolio UI showing a customer lookup and the three-layer MuleSoft request path

MuleSoft API-led integration  |  ReactJS  |  CloudHub 2.0

## Contents

Use the linked section names to navigate this project guide.

- [Tools and Workspace](#tools-and-workspace)
  - [Anypoint Studio](#anypoint-studio)
- [VS Code and ReactJS](#vs-code-and-reactjs)
  - [Local development loop](#local-development-loop)
- [Project Overview](#project-overview)
  - [What the project demonstrates](#what-the-project-demonstrates)
  - [Repository layout](#repository-layout)
  - [Project boundaries](#project-boundaries)
- [Solution Architecture](#solution-architecture)
  - [Why separate the APIs](#why-separate-the-apis)
  - [Local ports](#local-ports)
- [API Contracts and Implementation](#api-contracts-and-implementation)
  - [Example routing path](#example-routing-path)
  - [Contract-first workflow](#contract-first-workflow)
- [Request Lifecycle and Example](#request-lifecycle-and-example)
  - [Example request](#example-request)
  - [Example response](#example-response)
- [Manual Test Scenarios](#manual-test-scenarios)
  - [Repeatable success request](#repeatable-success-request)
- [Local Development and Release](#local-development-and-release)
  - [Run the local sample](#run-the-local-sample)
  - [Build, publish, and deploy](#build-publish-and-deploy)
  - [Configuration and secrets](#configuration-and-secrets)
- [Exchange and CloudHub Evidence](#exchange-and-cloudhub-evidence)
- [Portfolio Scope and Next Steps](#portfolio-scope-and-next-steps)
  - [What this sample demonstrates today](#what-this-sample-demonstrates-today)
  - [Current scope](#current-scope)
  - [Potential enterprise extensions](#potential-enterprise-extensions)
  - [Resume description](#resume-description)

> PROJECT AT A GLANCE  One ReactJS front end, three Mule APIs, and a mock customer profile service. The sample demonstrates API-led separation and a repeatable local-to-CloudHub workflow.

## Tools and Workspace

The project uses Anypoint Studio to build, run, and inspect the Mule APIs, and Visual Studio Code to manage and launch the ReactJS front end. The screenshots below document the local development setup used for this sample.

### Anypoint Studio

Studio shows the Experience API listener and APIkit router, the three Mule applications deployed in the local runtime, and runtime logs from the sample request path.

![Anypoint Studio workspace showing the Experience API flow, Mule palette, local applications, and runtime console](portfolio-assets/02-anypoint-studio.png)

*Figure 1. Mule API flows and local runtime in Anypoint Studio*

> TOOLS IN VIEW  Anypoint Studio  |  Mule Runtime  |  APIkit  |  HTTP Connector  |  DataWeave  |  Runtime console

## VS Code and ReactJS

The ReactJS application is maintained in its own folder. VS Code provides the project explorer and integrated terminal for installing dependencies and running Vite during local development.

![Visual Studio Code workspace showing the ReactJS project, source files, deployment scripts, and integrated terminal](portfolio-assets/03-vscode-reactjs.png)

*Figure 2. ReactJS project and development terminal in Visual Studio Code*

### Local development loop

```bash
cd reactJS-project
npm install
npm run dev
```

With the Mule APIs running in Studio, open the Vite URL (typically http://localhost:5173) and submit a customer lookup. The browser sends the request to the Experience API through the Vite development proxy.

## Project Overview

This sample demonstrates a customer profile lookup from the browser through a MuleSoft API-led architecture. The ReactJS screen submits a name and two-letter country code. The Experience API accepts the UI request, the Process API enriches and orchestrates it, and the System API returns mock customer data.

### What the project demonstrates

- A ReactJS and Vite user interface that calls a backend API using JSON.

- Three API layers with separate RAML contracts and APIkit routing.

- Mule flows for request handling and downstream API orchestration.

- DataWeave for request normalization, country lookup, and response mapping.

- Maven-based packaging and deployment scripts for Exchange and CloudHub 2.0.

### Repository layout

```text
reactJS-project/                         ReactJS and Vite interface
mule-projects/customer-portal-experience-api/  Experience API
mule-projects/customer-profile-process-api/    Process API
mule-projects/mock-customer-system-api/         Mock System API
deployment/                                     Build, publish, and deploy scripts
```

### Project boundaries

The System API is intentionally a mock backend for learning. The sample illustrates API-led design and integration mechanics; it does not connect to a live Salesforce org or contain production customer records.

## Solution Architecture

The request moves from the presentation layer through the Experience, Process, and System APIs. Each Mule API owns a distinct responsibility and exposes a contract described in RAML.

**ReactJS → Experience API → Process API → System API**

| Layer | Primary responsibility | This sample |
| --- | --- | --- |
| ReactJS UI | Collect user input and present the profile response. | Vite app calls POST /api/customer. |
| Experience API | Expose a UI-friendly endpoint and coordinate the experience. | APIkit routes POST /customer; DataWeave normalizes input and adapts output. |
| Process API | Apply reusable business orchestration and transformations. | Looks up country name, calls System API, and adds process metadata. |
| System API | Isolate the backend system interface. | Returns a mock customer record using DataWeave. |

### Why separate the APIs

The separation keeps the UI-facing contract independent from backend details. The Process API can coordinate business logic without putting it in the browser, while the System API gives the backend a stable interface. In a real enterprise implementation, the mock System API can be replaced by a governed connector-backed service.

### Local ports

The local demo uses Experience API on 8083, Process API on 8082, and System API on 8084. The React development server runs on 5173 and proxies /api requests to the Experience API.

## API Contracts and Implementation

The project keeps API design artifacts, flow routing, and transformations visible as separate learning concerns.

| Technology | Role in the sample | Where to look |
| --- | --- | --- |
| RAML 1.0 | Defines endpoint paths, methods, request and response shapes, and examples. | Each Mule project: src/main/resources/api/*.raml |
| APIkit | Uses the RAML contract to route HTTP requests to the matching Mule flow. | Each Mule project: src/main/mule/*apikit.xml |
| Mule flows | Connect listeners, APIkit routers, HTTP requests, logging, and error handling. | Each Mule project: src/main/mule/*.xml |
| DataWeave | Normalizes input, maps country codes, and shapes JSON responses. | Each Mule project: src/main/resources/dw/*.dwl |
| ReactJS + Vite | Renders the form and response and sends JSON to the Experience API. | reactJS-project/src/App.jsx and vite.config.js |

### Example routing path

```text
RAML resource:       POST /customer
Listener base path:  /api/*
APIkit mapping:      resource="/customer", action="post"
Flow responsibility: Experience → Process → System
```

### Contract-first workflow

The RAML files are the API contracts. They can be reviewed and designed in Anypoint Design Center; the Mule implementation remains in the local projects and is built with Anypoint Studio or Code Builder. Publishing a specification to Exchange makes it discoverable, while publishing a Mule application asset makes its version available for deployment and reuse.

> NAMING NOTE  The Mule component is called a Mule flow. “MLflow” is a separate machine-learning lifecycle product and is not used by this project.

## Request Lifecycle and Example

| Step | Component | Action |
| --- | --- | --- |
| 1 | ReactJS | Submits { name, countryCode } as JSON to the Experience API. |
| 2 | Experience API | APIkit routes the request; DataWeave trims the name and normalizes the country code. |
| 3 | Process API | DataWeave resolves the country name and prepares the downstream request. |
| 4 | System API | Returns a mock customer record; the Process API and Experience API add their response metadata. |
| 5 | ReactJS | Renders the greeting, customer ID, status, plan, and country. |

### Example request

```bash
curl -i -X POST 'http://localhost:8083/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"IN"}'
```

For CloudHub, replace the localhost URL with the current Experience API endpoint shown in Runtime Manager. CloudHub hostnames are environment-specific and may change after redeployment.

### Example response

```json
{
  "name": "Merlin",
  "countryCode": "IN",
  "countryName": "India",
  "message": "Hello, Merlin! Here is your mock customer profile for India.",
  "customer": { "id": "CUST-1001", "status": "ACTIVE", "plan": "Learning Demo" },
  "source": "System API mock data",
  "systemApi": "System API",
  "processApi": "Process API",
  "experienceApi": "Experience API"
}
```

## Manual Test Scenarios

Run these checks against the local Experience API at http://localhost:8083/api/customer or the current CloudHub Experience API hostname. Use Postman or curl, and confirm the response in both the client and Mule logs.

| Scenario | Input or action | Expected result |
| --- | --- | --- |
| Successful lookup | POST JSON: {"name":"Merlin","countryCode":"IN"}. | HTTP 200; countryName is India, customer status is ACTIVE, and the response identifies the API-led path. |
| Supported country | Repeat with countryCode CA, GB, or US. | HTTP 200; countryCode is accepted and the returned countryName matches the selected code. |
| Name whitespace | Send name with leading/trailing spaces, e.g. "  Merlin  ". | The Experience API normalizes the name; response uses the trimmed name. |
| Missing or empty name | Omit name or send an empty string. | RAML request validation rejects the request; inspect the client response for a 4xx validation error. |
| Unsupported country code | Send a code outside US, IN, CA, GB, such as ZZ. | RAML request validation rejects the request; inspect the client response for a 4xx validation error. |
| Downstream API unavailable | Stop the System API, then submit a valid request through the Experience API. | The request fails as a downstream error; verify the error response and relevant Process/System API logs. Restart the System API afterward. |

### Repeatable success request

```bash
curl -i -X POST 'http://localhost:8083/api/customer' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Merlin","countryCode":"IN"}'
```

> CHECK THE FULL PATH  A successful UI result alone is not enough to confirm every layer. Correlate the request with the Experience, Process, and System API logs, and verify the returned country and mock customer fields.

## Local Development and Release

### Run the local sample

Start the three Mule applications from Anypoint Studio. Then start the React development server in a terminal:

```bash
cd reactJS-project
npm install
npm run dev
```

Open the local Vite URL (typically http://localhost:5173), enter a name, choose a country, and submit. The Vite proxy sends /api/customer to the Experience API at 127.0.0.1:8083.

### Build, publish, and deploy

For a new release, increment the Mule application versions before publishing; Exchange release versions are immutable. Store Connected App credentials in a local secret manager or CI secret store, not in Git.

```bash
./deployment/scripts/build-mule-artifacts.sh
./deployment/scripts/publish-mule-artifacts.sh
./deployment/scripts/deploy-system-api-cloudhub2.sh
export SYSTEM_API_HOST="<system-api-host-from-runtime-manager>"
./deployment/scripts/deploy-process-api-cloudhub2.sh
export PROCESS_API_HOST="<process-api-host-from-runtime-manager>"
./deployment/scripts/deploy-experience-api-cloudhub2.sh
```

Deploy in dependency order: System API, then Process API, then Experience API. Set each downstream host from Runtime Manager before deploying the API that calls it. The React site has a separate static-site build and optional S3/CloudFront deployment script.

### Configuration and secrets

- Keep client IDs and secrets out of source files, screenshots, and Git history.

- Use local 127.0.0.1 properties for Studio and CloudHub host properties for deployed apps.

- Review the generated deployment property set when new runtime settings are added.

## Exchange and CloudHub Evidence

The supplied screenshots show the project’s Mule API assets in the ABC Exchange business group and the three Mule applications running in the Sandbox environment at the time of capture.

![Anypoint Exchange ABC business group showing the three API assets and the System API application asset](portfolio-assets/04-exchange-assets.png)

*Figure 1. API specifications and the System API application asset in Exchange*

![Runtime Manager Sandbox list showing Experience, Process, and System API applications running on CloudHub 2.0](portfolio-assets/05-cloudhub-runtime-manager.png)

*Figure 2. Experience, Process, and System APIs shown as running in CloudHub 2.0*

> SCREENSHOT CONTEXT  These are point-in-time Sandbox captures. Confirm current application status and hostnames in Runtime Manager before testing or promoting a release.

## Portfolio Scope and Next Steps

### What this sample demonstrates today

The project demonstrates a ReactJS front end, API-led MuleSoft layers, RAML contracts, APIkit routing, Mule flow orchestration, DataWeave transformations, Exchange publishing, and CloudHub 2.0 deployment automation.

### Current scope

The backend is mock data and the deployment scripts are a learning workflow. The repository should not be described as a live Salesforce integration or as a production-ready customer-data platform unless those capabilities are added and validated.

### Potential enterprise extensions

- Replace the mock System API with a real backend connector and environment-specific connection configuration.

- Add MUnit coverage for API flows, country mappings, error handling, and downstream failures.

- Add API Manager policies, authentication, rate limits, and documented authorization requirements.

- Add GitHub Actions for pull-request checks, release versioning, Exchange publication, and gated CloudHub deployment.

- Add structured logging, dashboards, alerts, and a rollback procedure for deployed releases.

### Resume description

> PROJECT SUMMARY  Built a ReactJS customer experience integrated with a MuleSoft API-led architecture. Defined RAML contracts, routed requests with APIkit, transformed JSON with DataWeave, and automated Exchange and CloudHub 2.0 release steps.
