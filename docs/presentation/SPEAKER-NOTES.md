# LabLedger speaker notes

Use with the 12-slide PDF/PPTX. These notes guide a live presentation; unperformed cloud/browser actions remain disclosed as pending.


## Slide 1: LabLedger

Introduce the original campus equipment-loan domain. Identify yourself as Jaivardhan D Rao, roll 10117, Group A.
The screenshot is a genuine earlier School-profile capture of local Kubernetes, not AWS. Every displayed loan is fictional.
State the scope accurately: the application, CI and local Kubernetes have run; real AWS apply and teardown remain pending approval.
The slides support a live presentation. The separate short video records only the actual local Terminal evidence, not a complete browser walkthrough.


## Slide 2: One clear equipment-loan lifecycle

A borrowing request moves through requested, collected and returned. Only a collected loan past its due date is overdue.
A date has no UTC offset; the application evaluates today in Asia/Kolkata. Returning an item updates the statistics.
Explain the responsive table, keyboard access, filters and create/edit dialogs. The mobile capture is genuine and predates the later footer-only delivery change.
For the live demo open localhost:8088 only in the School Chrome profile; create and remove a temporary fictional loan only when that write is authorized.


## Slide 3: Follow a request through the stack

The browser sends relative /api requests. Compose Nginx resolves the backend service; Kubernetes Ingress routes /api directly to the API ClusterIP Service.
The frontend serves static React assets. The backend validates inputs and persists loans through SQLAlchemy in PostgreSQL, with Alembic owning schema migration.
Prometheus scrapes both backend replicas and Grafana queries Prometheus. Metrics Server is a separate HPA dependency.
Kubernetes API and monitoring UIs are not public in this local demonstration. A real cloud public endpoint has not been created.


## Slide 4: 35 isolated tests, plus real-stack checks

The image is a native Terminal screenshot of the actual completed CI pytest output, part 2 of 2; it is explicitly not a fresh rerun. Both captures together show every test-result line.
The full evidence/pytest.txt contains all 35 passing API/migration tests. Tests isolate their SQLite database and mock dependencies; they do not use the running PostgreSQL data.
Mention invalid-input rejection, PUT replacement semantics, stats after return/delete, readiness failure and bounded metric route labels.
Separate real HTTP checks exercised the PostgreSQL/Compose path. The latest successful GitHub pipeline also ran the backend tests and nine frontend tests.


## Slide 5: Three healthy services; two non-root images

This is a fresh actual native Terminal capture. The Compose service is named database, while the Kubernetes StatefulSet is named labledger-postgres.
The API runs as UID10001 and frontend as UID101. The frontend is a Node-build to unprivileged-Nginx multi-stage image.
The read-only PostgreSQL session lists alembic_version and loans. No database record or schema was changed for this capture.
A prior forced backend IP-change check verified proxy DNS recovery and data preservation; see the original raw evidence. No images were rebuilt during this presentation capture.


## Slide 6: A real change reached the running application

Show the meaningful history and actual completed main-push run38915964006, all seven jobs green for source5cb1c80.
The earlier visible footer change went through runs38909132624 and38909739859. Helm4 rejected the first promotion preflight flag, so no deployment was claimed for that failure.
The repaired c2f4acf revision then passed CI and completed exact-Git-archive promotion: two Ready API and UI replicas, new footer served, old footer absent.
The current source-only cloud-preparation commit5cb1c80 is green but is not claimed deployed locally. Full SHAs identify images; the workflow does not deploy automatically to AWS.


## Slide 7: The scan gate found a problem, then verified the repair

Explain that the initial Debian-based backend image failed strict HIGH/CRITICAL scanning. Its original failed report was retained.
Replacing the runtime with Alpine and rebuilding produced clean backend/frontend reports. Both amd64 and arm64 images must pass before canonical multiarch publication.
Trivy uses HIGH,CRITICAL with ignore-unfixed=false and exit-code1; no broad ignore gate was added. All four actual downloaded current CI reports have zero HIGH/CRITICAL findings.
A clean container scan is a bounded observation, not proof of total application security. Separate exact-credential and secret scans checked the public tree/history; credentials and local state stay outside Git.


## Slide 8: Helm release 2 is running in the dedicated local cluster

Show the exact labledger-capstone context rather than relying on the current global context. The older coursework cluster is preserved.
Both UI and API Deployments have two Ready replicas. Their Services are ClusterIP. PostgreSQL is a StatefulSet with a PVC; the migration Job completed successfully.
A Completed migration Job is expected and does not mean application Pods are unhealthy. Probes gate application readiness on migration/database state.
The local storage class is standard, not the prepared AWS gp3 class. These are genuine local Kubernetes results, not EKS results.


## Slide 9: Resilience was exercised, not only configured

Use the retained original load/drill logs; this evidence is historical and no new fault or load is injected during this presentation capture.
The actual HPA rose from 2 to 4 Ready API Pods under CPU load and later returned to 2. The persistent read load recorded 2338 requests with zero failures.
A deliberately broken Service selector produced503/no endpoints; restoring the selector restored200. One earlier drill was affected by controller reconciliation and is retained separately.
Explain readiness vs liveness, Service selectors vs Pod labels, and why Metrics Server and CPU requests are required for HPA. HPA scales Pods, not worker nodes.


## Slide 10: Actual application scraping is healthy

This is the genuine unfiltered School-profile browser screenshot after the documented local-only configuration repair:14 applicable targets UP across13 pools.
The original three optional loopback-only control-plane endpoint failures are still retained. Their endpoints did not become reachable; the local override excludes those inapplicable component scrapes.
Both API replicas remain scraped. Grafana authenticated API previously returned the six-panel dashboard with positive actual traffic samples, but no populated browser screenshot is claimed.
Open the real Grafana UI using legitimate private login in the School profile. Never show a login page or dashboard JSON as evidence of a populated panel.


## Slide 11: AWS is prepared, but has not been deployed

The actual read-only personal-account plan proposes62 creates, zero changes and zero deletes. Nine mock tests and provider validation passed, but these are not proof of a running EKS cluster.
The proposed isolated Mumbai environment contains a VPC, two public/two private subnets, one NAT, one EKS cluster/worker and a Terraform-owned HTTP NLB.
Official API prices support a two-hour bounded illustrative estimate of2.432349USD before tax; the approved conditional ceiling is10USD/max2h. This is not a hard automated billing cap.
Exact IAM/temporary admin/controller RBAC/public-network and package-visibility decisions remain pending. No access grant, AWS resource, cost, Console screenshot or destroy success is claimed.


## Slide 12: Present the verified work, then review the submission

Use the PDF or editable slides as a speaking guide. Play the separate native Terminal-only recording as supporting evidence, not a claim that the complete app/browser demo was recorded.
For a full live/remote walkthrough, open local UI/Swagger/Prometheus/Grafana in the School Chrome profile, show the genuine green run and package pages, and explain the retained change-to-rollout sequence.
Finish any actual AWS work only after the pending access/visibility decisions and legitimate Console authentication. Capture and clean up real resources before claiming the cloud module.
The school form is filled for Jaivardhan D Rao, Group A, roll 10117 and the official SST email. The user reviews and submits manually. No submission or receipt is claimed.
