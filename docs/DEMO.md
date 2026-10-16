# Demonstration and short presentation

Use only the SST Chrome profile for browser work. Demonstrate actual running services and real command results. Do not read a script as though an unperformed deployment succeeded.

## Suggested slides / speaking order

1. **Problem and original domain:** a campus equipment desk must track request, collection, overdue status and return. LabLedger models equipment loans, not project tasks.
2. **Request flow:** React → Nginx/Ingress → FastAPI → PostgreSQL. Show the route and explain why browser calls are relative.
3. **Correctness:** 35 isolated tests plus real PostgreSQL/Compose HTTP checks; explain one validation and one failure-path test.
4. **Reproducible artifacts:** non-root images, locked app dependencies, both architectures scanned, full Git SHA tags.
5. **Deployment:** namespace, migrations, two replicas, ClusterIP, Ingress, readiness/liveness and HPA. Explain the difference between a Pod running and the application being ready.
6. **Operations:** real Prometheus target and Grafana request/latency data. Explain one actual failure and repair from the troubleshooting record.
7. **Cloud scope:** show actual AWS evidence only if separately approved and performed; otherwise disclose the missing module and show configuration/mock checks accurately.
8. **Delivery change:** show a meaningful small UI change, its commit, actual green pipeline and the matching deployed revision.

## Walkthrough checklist

- Open the application; point out that example student records are fictional.
- Create a borrowing request, collect it, return it, edit details and remove a temporary record.
- Open Swagger and exercise GET/POST/PUT/DELETE.
- Show PostgreSQL tables and an Alembic revision.
- Show test output and Docker process identities.
- Show the real commit history, workflow URL and scanned/published image SHA.
- Show actual Pods, Services, Helm release and a browser request through Ingress.
- Generate modest local API traffic, then show target UP and populated Grafana panels.
- Perform a controlled image/selector troubleshooting drill in the dedicated lab, preserve data and restore the healthy workload.
- Make a small reviewed change and commit it; push only to the approved repository. Watch the actual delivery run, then use the explicit promotion script after it turns green. Verify the image SHA and visible UI change.

## Important distinctions to explain

A local image tag is not a published SHA artifact. A rendered chart is not a running cluster. A Prometheus configuration is not a scrape result. A dashboard JSON is not a populated panel. A mock Terraform plan is not AWS infrastructure. A prepared form is not a submitted response.

A remote recorded walkthrough must be captured from the student's actual run. This guide contains no synthetic video, voice, screenshot or receipt. Leave final form submission to the student after review.
