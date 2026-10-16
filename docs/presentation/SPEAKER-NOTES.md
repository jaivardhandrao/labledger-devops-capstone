# LabLedger speaker notes

Local and actual temporary AWS evidence; captures and remaining limitations are identified.

## Slide 1: LabLedger

Introduce the original campus equipment-loan domain. Identify yourself as Jaivardhan D Rao, roll 10117, Group A.
The screenshot is a genuine earlier School-profile capture of local Kubernetes, not AWS. Every displayed loan is fictional.
The application, CI, local Kubernetes and temporary personal AWS EKS ran successfully. Actual cleanup was verified separately before this final deck was built.
The title image remains the original local UI capture, not an AWS browser image. New Terminal/API evidence documents the cloud run; private browser captures are not embedded while publication approval is pending.

## Slide 2: One clear equipment-loan lifecycle

A borrowing request moves through requested, collected and returned. Only a collected loan past its due date is overdue.
A date has no UTC offset; the application evaluates today in Asia/Kolkata. Returning an item updates the statistics.
Explain the responsive table, keyboard access, filters and create/edit dialogs. The mobile capture is genuine and predates the later footer-only delivery change.
For the live demo open localhost:8088 only in the School Chrome profile; create and remove a temporary fictional loan only when that write is authorized.

## Slide 3: Follow a request through the stack

The browser sends relative /api requests. Compose Nginx resolves the backend service; Kubernetes Ingress routes /api directly to the API ClusterIP Service.
The frontend serves static React assets. The backend validates inputs and persists loans through SQLAlchemy in PostgreSQL, with Alembic owning schema migration.
Prometheus scrapes both backend replicas and Grafana queries Prometheus. Metrics Server is a separate HPA dependency.
The temporary cloud path was public HTTP NLB to NodePort30080, NGINX Ingress, ClusterIP Services and PostgreSQL. Monitoring remained loopback-only. The endpoint was retired after evidence capture.

## Slide 4: 35 isolated tests, plus real-stack checks

The image is a native Terminal screenshot of the actual completed CI pytest output, part 2 of 2; it is explicitly not a fresh rerun. Both captures together show every test-result line.
The full evidence/pytest.txt contains all 35 passing API/migration tests. Tests isolate their SQLite database and mock dependencies; they do not use the running PostgreSQL data.
Mention invalid-input rejection, PUT replacement semantics, stats after return/delete, readiness failure and bounded metric route labels.
Separate real HTTP checks exercised the PostgreSQL/Compose path. The latest successful GitHub pipeline also ran the backend tests and nine frontend tests.

## Slide 5: Three healthy services; two non-root images

This is an original actual local Terminal capture. The Compose service is named database, while the Kubernetes StatefulSet is named labledger-postgres. The later cloud database/table and container UID results are separate.
The API runs as UID10001 and frontend as UID101. The frontend is a Node-build to unprivileged-Nginx multi-stage image.
The read-only PostgreSQL session lists alembic_version and loans. No database record or schema was changed for this capture.
A prior forced backend IP-change check verified proxy DNS recovery and data preservation; see the original raw evidence. No images were rebuilt during this presentation capture.

## Slide 6: A real change reached the running application

Show actual completed run 38934060961, seven successful jobs for 06909ce. It tested the controller fix and published both multiarch SHA image tags.
Anonymous exact-tag manifest fetches succeeded. A deliberate personal-account Helm promotion then rolled the cloud application to exactly06909ce, release2, with Ready UI/API Pods.
The screenshot combines explicitly completed CI/promotion records with actual current Deployment image queries. A later documentation-only commit is not a newly tested image.
The earlier visible footer change and c2f4acf local rollout remain independently documented. CI publishes images; AWS promotion is an explicit guarded step, not automatic cloud access.

## Slide 7: The scan gate found a problem, then verified the repair

Explain that the initial Debian-based backend image failed strict HIGH/CRITICAL scanning. Its original failed report was retained.
Replacing the runtime with Alpine and rebuilding produced clean backend/frontend reports. Both amd64 and arm64 images must pass before canonical multiarch publication.
Trivy uses HIGH,CRITICAL with ignore-unfixed=false and exit-code1; no broad ignore gate was added. Earlier downloaded reports have zero HIGH/CRITICAL findings. Fresh06909ce metadata verifies all four strict scan jobs succeeded; their raw report ZIPs were not downloaded.
A clean container scan is a bounded observation, not proof of total application security. Separate exact-credential and secret scans checked the public tree/history; credentials and local state stay outside Git.

## Slide 8: Helm release 2 ran on the dedicated EKS cluster

The screenshot displays the explicitly saved actual cloud API snapshot, with its original capture time and source file. It is not represented as a fresh cluster query after teardown. The existing local coursework cluster was preserved.
Both UI and API Deployments had two Ready replicas after HPA cooldown. Their Services are ClusterIP. PostgreSQL used an encrypted 2GiB gp3 PVC; the migration Job completed successfully.
A Completed migration Job is expected and does not mean application Pods are unhealthy. Probes gate application readiness on migration/database state.
Actual public NLB routing and cloud CRUD succeeded. This is genuine cloud evidence captured before approved teardown, not a claim that the temporary endpoint remains online.

## Slide 9: Resilience was exercised, not only configured

Use the actual cloud load/drill records. HPA rose from 2 to 4 Ready API Pods and returned to 2; the worker count remained one.
The 90-second burst recorded 7,431 HTTP200 and 12 failures. Failure categories were not retained, so their cause is not established. A separate lower-rate recovery check passed 40/40; this is not a claim that the burst workload was repaired.
A deliberately broken cloud Service selector produced502/no endpoints; exact restoration restored200. The initial EndpointSlice-null instrumentation error and its successful finally-restoration are retained separately.
Explain readiness vs liveness, Service selectors vs Pod labels, and why Metrics Server and CPU requests are required for HPA. HPA scales Pods, not worker nodes.

## Slide 10: Actual application scraping is healthy

This is a genuine native Terminal display of explicitly saved cloud checks, not a browser dashboard. Prometheus returned 16/16 UP before scaling; HPA temporarily increased the API target count.
Grafana's authenticated API returned the actual six-panel dashboard, six traffic series and positive samples. Credentials remained in RAM. A populated browser panel is still a separate capture requirement.
The initial local loopback-only control-plane failures and local repair remain historical evidence. EKS uses its separately documented managed-control-plane scrape profile.
Private Console/app/Prometheus browser images were captured separately and remain unpublished pending their specific publication approval. No browser pixels are embedded here.

## Slide 11: Real AWS deployment, then verified cleanup

The actual frozen personal-account plan created 62 resources, zero changes/deletions. Mumbai EKS 1.34 and its managed t3.large group became ACTIVE. The VPC had two public/two private subnets, NAT and a Terraform-owned HTTP NLB.
The screenshot is an original native Terminal capture displaying actual completed destroy output and explicitly recorded post-deletion API checks. The separate apply capture preserves the actual 62-create output and ACTIVE EKS/node-group responses. Separate Console captures remain private until publication approval.
After actual runtime evidence, the disposable PostgreSQL PVC/EBS was removed while CSI/node permissions remained available. A separately reviewed 62-delete Terraform plan removed the new infrastructure; post-cleanup API/state checks are linked in the evidence gallery.
The final build requires a successful actual cleanup-verification file. The approved ceiling was US$10 / maximum two hours. The US$2.43 before-tax scenario is a planning estimate, not a measured final bill or automated billing cap.

## Slide 12: Present the verified work and its limits

Use the PDF or editable slides as a speaking guide. Play the separate native Terminal-only recording as supporting evidence, not a claim that the complete app/browser demo was recorded.
For a full live/remote walkthrough, open local UI/Swagger/Prometheus/Grafana in the School Chrome profile, show the genuine green run and package pages, and explain the retained change-to-rollout sequence.
Actual cloud deployment, delivery update, metrics, troubleshooting and project-only cleanup are complete. The temporary AWS endpoint is retired; local demonstration instructions remain reproducible.
The student reported manually submitting the form. No automated submission, instructor acceptance or submission receipt is claimed, and no further form actions are performed.
