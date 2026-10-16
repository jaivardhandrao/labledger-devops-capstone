# LabLedger frontend

React and Vite interface for a campus equipment lending desk. The frontend reads actual API records; it does not seed or fabricate loans. All fonts and icons are local/system assets, with no external font or image requests.

## Run locally

Use Node 22.12+ or Node 24 LTS, start the FastAPI backend on port 8000, then:

```sh
npm ci
npm test
npm run dev
```

Vite serves the interface on its displayed local address and proxies `/api`, `/health`, `/ready` and `/metrics` to `127.0.0.1:8000`. The root Compose stack serves the production interface at `http://localhost:3000` instead.

```sh
npm run build
npm run preview
```

`preview` serves the build for inspecting static output; use Compose for the full production proxy and API integration.

## Equipment workflow

- Create a loan with equipment, borrower, calendar return date and optional notes.
- Open Edit to read the current record, update details or change its status from Requested to Collected to Returned. The server remains the authority for validation.
- Search equipment, borrower and notes; combine the search with status filters.
- Collected items due before the user's current local calendar day are overdue. Requested and returned records are never overdue. Active includes requested and collected loans.
- Keep returned records for history. Delete asks for confirmation and permanently removes a record through the API.

The app displays loading, connection failure, empty-register and no-filter-match states. Forms retain input after an API error. Native HTML dialogs trap focus, support Escape, have accessible names, and restore focus to their invoking action. Reduced-motion preferences and visible keyboard focus are respected. The table scrolls within its container on small screens.

## HTTP contract

| Action | Request |
| --- | --- |
| Load register | `GET /api/loans` (JSON array) |
| Read latest loan before editing | `GET /api/loans/{id}` |
| Create | `POST /api/loans` |
| Edit / mark returned | `PUT /api/loans/{id}` |
| Remove | `DELETE /api/loans/{id}` (204 accepted) |

POST/PUT JSON fields: `equipment`, `borrower`, `due_date` (`YYYY-MM-DD`), `status` (`requested`, `collected`, `returned`), `notes`. Read responses also include `id` and `created_at`. Overview counts are derived from the retrieved register, so they reflect exactly the records currently available to the UI.

## Production container

`Dockerfile` builds with Node, copies only static output into Nginx, and runs the final image as UID/GID `101:101` on port `8080`. The direct Nginx entrypoint avoids startup scripts modifying configuration. For a read-only container filesystem, mount writable `/tmp`, `/var/cache/nginx`, and `/var/run` directories.

The bundled `nginx.conf` resolves the Compose DNS name `backend:8000` through Docker's embedded DNS (`127.0.0.11`), refreshing its cached address after 10 seconds so backend container recreation does not leave Nginx using an old IP. A variable `proxy_pass` with no URI suffix forwards the original path and query string, preserving `/api/loans`. In Kubernetes, the chart mounts a separate Nginx ConfigMap using its stable backend Service DNS; the Docker-only resolver does not belong in that configuration. SPA fallback applies only to the frontend route; failed API requests keep their API status rather than returning index.html.

Use immutable image digests when promoting images after a successful scan. Base image tags intentionally receive security patch updates; actual image identities and security findings must come from the current build/Trivy evidence.

## Validation boundary

`npm test` covers date/overdue boundaries, summaries and combined filters, API error formatting, JSON method handling, 204 responses, offline failures and cancellation. `npm run build` checks the JSX/CSS production pipeline. These checks do not replace a real browser walkthrough against the running stack; screenshots and UI integration evidence should be captured from the authorized School Chrome profile.
