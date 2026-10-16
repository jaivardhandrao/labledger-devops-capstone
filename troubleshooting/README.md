# Failures encountered and repairs

These are actual integration findings, not invented incidents.

## Strict security gate caught OS vulnerabilities

The first backend image used `python:3.12-slim`. Trivy reported HIGH-severity Debian packages, with no fixed version listed for those findings in the captured database. The original report is retained under `evidence/trivy-backend-debian-initial.json`. We replaced that base with maintained `python:3.12-alpine`, pinned the Linux Greenlet dependency and retested Python, Psycopg, timezone support, migrations and the API. The strict HIGH/CRITICAL scan passed for the replacement; no ignore file, severity exception or ignore-unfixed flag was used.

The result means no vulnerabilities at those severities were reported for that exact image and scanner database at scan time. It is not a guarantee that the software is secure or that future scans remain clean.

## Backend replacement changed its Docker address

The initial Nginx upstream resolved the Compose backend hostname only during startup. Backend replacement could leave the proxy pointing at the old address. The fix uses Docker's runtime resolver, a variable upstream and the complete original request URI. An actual forced IP-change test moved the backend address while preserving the frontend and PostgreSQL containers: the proxy recovered and all three fictional records remained unchanged. See the recorded regression evidence for timing and container IDs.

## Monitoring schema mismatch

The first real Prometheus installation rejected a namespace selector that used `matchNames` in the Prometheus selector field. The correct selector uses namespace labels; ServiceMonitor target selection separately uses `matchNames`. Template checks alone did not catch that CRD validation distinction. The values, instructions and semantic check were repaired; the original failure log was preserved.

## Local image download and resource pressure

The local cluster had registry/CDN connectivity trouble for an exporter image and temporary API timeouts while unpacking monitoring images. The dedicated lab received more CPU/RAM within the existing Docker VM, and approved host image pulls/loads were used. Only the new lab and this project's Compose services were adjusted; older contexts and database volumes were preserved. Final rollout/status output is separate evidence.

## Classroom drill to demonstrate

In the dedicated lab only, a nonexistent image can create an image-pull failure while rolling-update settings keep the previous replicas serving. Inspect Pod status/events and the configured image, then restore the exact reviewed image. Alternatively, a deliberately incorrect Service selector produces no endpoints; compare selectors with Pod labels and restore the correct value. Do not perform these exercises in another context or shared production environment. Capture real output when running the drill; this paragraph is a procedure, not proof that it has occurred.
