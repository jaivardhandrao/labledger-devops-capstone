# LabLedger speaker notes

Local and actual temporary AWS evidence; captures and remaining limitations are identified.

Publication note: the student approved this reviewed deck and existing video on 26 October. The deck bytes and notes below preserve the earlier review-stage wording. Current repository availability is recorded in demo/README.md; private browser captures remain excluded.

## Slide 1: LabLedger

Introduce the original campus equipment-loan domain. Identify yourself as Jaivardhan D Rao, roll 10117, Group A.
The screenshot is a genuine earlier School-profile capture of local Kubernetes, not AWS. Every displayed loan is fictional.
The application, CI, local Kubernetes and temporary personal AWS EKS ran successfully. Actual cleanup was verified separately before this final deck was built.
The title image remains the original local UI capture, not an AWS browser image. This 26 October review corrects documentation using saved 16 October evidence, with no fresh runtime checks. Private browser captures are not embedded. ArgoCD is not implemented and the complete slides-first presentation remains unrecorded.

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

The displayed native Terminal image is historical cloud evidence: 06909ce, actual seven-green CI 38934060961, then exact-SHA EKS Helm release 2. It is not the final local revision.
The later local source change f271a837 has all seven jobs green in CI 38977458426. The genuine 3m54.5s recording shows a new accessibility refinement, 9 frontend tests/build, personal Git push, actual CI wait, anonymous pulls of the exact published ARM64 images, and local Helm release 4.
All four Ready local app Pods matched the published platform config digests. Separate School-profile captures show matching Arduino/requested filters and the new Show all loans reset.
The video is prepared privately under demo/ as a review candidate. It is Terminal-only and does not cover slides-first narration, AWS Console, ArgoCD or a full browser walkthrough. Delivery uses explicit Helm; no ArgoCD sync or automatic GitOps reconciliation is implemented.

## Slide 7: The scan gate found a problem, then verified the repair

Explain that the initial Debian-based backend image failed strict HIGH/CRITICAL scanning. Its original failed report was retained.
Replacing the runtime with Alpine and rebuilding produced clean backend/frontend reports. Both amd64 and arm64 images must pass before canonical multiarch publication.
Trivy uses HIGH,CRITICAL with ignore-unfixed=false and exit-code1; no broad ignore gate was added. Earlier downloaded reports have zero HIGH/CRITICAL findings. Historical 06909ce and final local f271a837 metadata each verify all four strict scan jobs succeeded; their fresh raw report ZIPs were not downloaded.
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

## Slide 10: Monitoring evidence has a clear scope

This is a genuine native Terminal display of explicitly saved cloud checks, not a browser dashboard. Prometheus returned 16/16 UP before scaling; HPA temporarily increased the API target count.
Grafana's authenticated API returned the actual six-panel dashboard, six traffic series and positive samples. The genuine local six-panel browser capture was completed 16 October at 23:03:48 UTC after service recovery and remains private. Its one-hour range includes earlier revisions, rollout and recovery; it is not exclusively f271a837 or AWS evidence.
The initial local loopback-only control-plane failures and local repair remain historical evidence. EKS uses its separately documented managed-control-plane scrape profile.
Private Console/app/Prometheus browser images were captured separately and remain unpublished pending their specific publication approval. No browser pixels are embedded here.

## Slide 11: Real AWS deployment, then verified cleanup

The actual frozen personal-account plan created 62 resources, zero changes/deletions. Mumbai EKS 1.34 and its managed t3.large group became ACTIVE. The VPC had two public/two private subnets, NAT and a Terraform-owned HTTP NLB.
The screenshot is an original native Terminal capture displaying actual completed destroy output and explicitly recorded post-deletion API checks. The separate apply capture preserves the actual 62-create output and ACTIVE EKS/node-group responses. Separate Console captures remain private until publication approval.
After actual runtime evidence, the disposable PostgreSQL PVC/EBS was removed while CSI/node permissions remained available. A separately reviewed 62-delete Terraform plan removed the new infrastructure; post-cleanup API/state checks are linked in the evidence gallery.
The final build requires a successful actual cleanup-verification file. The approved ceiling was US$10 / maximum two hours. The US$2.43 before-tax scenario is a planning estimate, not a measured final bill or automated billing cap.

## Slide 12: Present the verified work and its limits

This is a local review candidate, not a claim that the full assignment is ready. The 26 October 14:11 IST class announcement requires the video and PPT/PDF under demo/ in the same submitted repository by EOD; 14:17 IST also permits a Drive-video link in Markdown under demo/. No exact EOD clock time was specified in the supplied announcement.
M10 is README 2 marks, video 2, slides 1. The guide says a missing video yields zero for M10 only. Assessment remains the instructor's decision.
The 3m54.5s Terminal recording covers a genuine source change, push, CI and local deployment. It does not start with these slides or show the complete AWS Console, ArgoCD synced/GitOps, Kubernetes/Prometheus/Grafana browser flow. ArgoCD is not implemented; direct Helm deployment is not a substitute for it.
A genuine local populated Grafana screenshot exists privately, including earlier revisions and recovery. Saved AWS evidence documents a retired environment; no restart or provisioning is authorized. No new runtime checks were performed for this docs-only review.
The student reported manually submitting the form. No receipt, instructor acceptance, resubmission or new form action is claimed. Publishing the prepared demo/ and changed docs still requires specific approval.
