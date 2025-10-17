# Luxury Rent Platform UI

Static control surface for the three atomic microservices and the composite façade that powers the Luxury Rent experience. The goal is to exercise the platform grading rubric directly from the browser (hostable on Cloud Storage).

| Microservice | Purpose | Default base |
| --- | --- | --- |
| Users & Profile | Identity, eTag-protected profile reads | `http://localhost:7001` |
| Catalog & Inventory | Item discovery, query filters, pagination | `http://localhost:7002` |
| Orders & Rentals | Authoritative rentals; emits 201 on `POST /orders` | `http://localhost:7003` |
| Composite Gateway | Fan-out, logical FK checks, `/orders/{id}/confirm` → `/jobs/{jobId}` | `http://localhost:8080` |

> The defaults align with the composite microservice quick-start instructions and its threaded order orchestration, async jobs, and FK validation features [documented here](https://github.com/elegante-libero-hub-luxrent-platform/composite_microservice).

## Page map

| Page | Primary APIs | Highlights |
| --- | --- | --- |
| Home | `GET /health` (all services) | quick ping controls + demo checklist |
| Catalog | `GET /items`, `GET /search` | query params, pagination, relative links |
| Orders | `GET/POST /orders`, `POST /orders/{id}/confirm`, `GET /jobs/{jobId}` | 201 create, 202 confirm + polling, FK enforcement surfaced from composite |
| Profile | `GET /users/{id}` | stores upstream `ETag`, attaches `If-None-Match` for 304/412 demos |
| Login | none (client only) | configure bearer token, email, service endpoints |

## API scenarios covered

- **ETag correctness** – Profile page caches `ETag` from the Users service and replays it via `If-None-Match`, surfacing 200 vs 304 (or 412) flows.
- **Query params & pagination** – Catalog form builds `category`, `designer`, `available`, `page`, and `pageSize` queries against the atomic catalog service or the composite `/search`.
- **Linked data + relative paths** – Each catalog item renders relative hyperlinks (`items/{id}`, `orders?itemId=...`) plus the resolved absolute URL so graders can inspect both forms.
- **201 Created** – Orders form uses the atomic service to `POST /orders`, expecting a 201 plus body. Responses (headers + payload) are captured verbatim for review.
- **202 Accepted + polling** – Confirm buttons call the composite `POST /orders/{id}/confirm`, then poll the provided `/jobs/{jobId}` location until a terminal state arrives.
- **Threaded composite logic & FK checks** – When the catalog toggle switches to composite search, requests fan-out through the composite gateway which enforces logical FK rules before delegating downstream [per the service README](https://github.com/elegante-libero-hub-luxrent-platform/composite_microservice).

## Run locally

1. `git clone` the repository that contains this `luxury_rent_platform_ui` folder.
2. Open `index.html` directly in a modern browser **or** serve it (`python3 -m http.server 8088`) and visit `http://localhost:8088`.
3. Navigate to the **Login** tab to set:
   - Bearer token (optional) and audit email header.
   - Default user id (used by the Profile page and the Create Order form).
   - Base URLs for each microservice (defaults point to localhost ports in the composite repo quick start).
4. Use the remaining tabs to exercise endpoints. Every request + response (status, latency, headers, JSON) is persisted in the UI so you can screenshot or export evidence.

## Deploy on Cloud Storage

1. Build any static assets (already committed as `index.html` + `README.md`).
2. Choose or create a bucket: `gsutil mb -l <region> gs://luxury-rent-ui`.
3. Enable website hosting metadata: `gsutil web set -m index.html -e index.html gs://luxury-rent-ui`.
4. Upload: `gsutil rsync -R . gs://luxury-rent-ui`.
5. (Optional) Front the bucket with Cloud CDN/Load Balancer if HTTPS custom domains are required.

## Demo walkthrough / grading checklist

1. **Home** – Ping `/health` on all four services; capture status + latency for audit.
2. **Catalog** – Use atomic `/items` with filters, then toggle composite `/search` to prove query params, pagination, and linked relative paths.
3. **Profile** – Fetch the same user twice to show `ETag` storage, `If-None-Match`, and the resulting 304 (or 412) short-circuit.
4. **Orders** – Create an order (201) via the atomic service, then refresh the list via the composite aggregator to show stitched user/item data.
5. **Confirm order** – Use the Confirm button to trigger a composite 202. Observe the job card as it polls `/jobs/{jobId}` until the terminal state is returned.
6. **Docs** – Reference this README plus screenshots/logs for your submission package. Keep Trello/GitHub artifacts in sync with the checklist (owner: Eric).

## Endpoint map with responsibilities

| UI action | Microservice | HTTP verb(s) | Notes |
| --- | --- | --- | --- |
| Ping service health | All | `GET /health` | quick readiness check |
| Catalog search | Catalog / Composite | `GET /items`, `GET /search` | query params, pagination |
| Order feed | Orders / Composite | `GET /orders` | composite call pulls linked user/catalog records |
| Create order | Orders | `POST /orders` → 201 | surfaces FK/validation errors |
| Confirm order | Composite | `POST /orders/{id}/confirm` → 202 | returns job location |
| Poll job | Composite | `GET /jobs/{jobId}` | loops until done/failed |
| Profile | Users | `GET /users/{id}` + `If-None-Match` | demonstrates `ETag` handling |

## Tooling notes

- **Postman/Newman** – Reuse the flows above to expand the existing automation suites. Each UI section exposes the full request metadata (URL, headers, body) to make scripting trivial.
- **Playwright/Cypress** – Wrap the same flows to satisfy the “E2E pipeline” grading requirement. This UI already includes deterministic selectors (panel headings, button labels) to stabilize those tests.
- **Logging evidence** – Every response is rendered inside the app as prettified JSON with headers (including `ETag`, `Location`, etc.) for easy copy/paste into documentation.

## Troubleshooting

- **CORS** – When pointing at remote environments, ensure the upstream services send the correct `Access-Control-Allow-Origin` headers for the Cloud Storage website origin.
- **Authorization** – Populate the bearer token on the Login page if the microservices sit behind IAM/AuthN. The UI automatically injects `Authorization` + `X-User-Email` headers on every call.
- **Service discovery** – If a base URL is blank, calls to that service will short-circuit with a helpful error. Fill in the endpoints on the Login page and retry.
