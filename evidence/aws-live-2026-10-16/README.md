# Actual temporary AWS run — 16 October 2026

The personal Mumbai environment was created, exercised and **removed**. Terraform actually created 62 resources, then destroyed 62. Post-deletion service/state checks verified removal of the exact project EKS/VPC/NAT/NLB/EIP/EC2/EBS/ENI/IAM/OIDC/log resources and the three proven-new automatic service-linked roles. The existing default VPC and local coursework contexts were preserved. The complete verified run lasted **80.89 minutes**, within the approved two-hour window.

The temporary NLB and cloud loopback endpoints in these historical records are retired. No workplace AWS profile was used. Credentials, kubeconfig, raw state and full account/operator identifiers stay outside public Git. The US$2.43 before-tax planning scenario is not a measured final bill; actual final billing has not been verified.

## Exact revision and delivery

Initial images were 5cb1c80. The controller port/schema fixes were committed as **06909ce67803bad2563d0b2b3e227eb4e0c71d28**. [Fresh CI 38934060961](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38934060961) passed all seven jobs, including both test jobs, four strict component/architecture scan jobs and multiarch publication. Both exact SHA tags were actually readable anonymously. A deliberate guarded Helm promotion completed on EKS at 16:52:04 UTC, release 2. Current native evidence and later documentation commits are not new image builds.

Both API/UI Deployments had two Ready baseline replicas, with PostgreSQL on encrypted gp3 and real public CRUD. HPA rose to four Ready API Pods and returned to two while the worker count stayed one. The 90-second burst recorded 7,431 successful requests and 12 failures; failure categories were not retained, so their cause is not established. A separate lower-rate recovery passed 40/40. These observations are not a zero-error capacity or production-availability claim.

Prometheus returned 16/16 UP at the recorded baseline. API target counts changed during HPA. Grafana's authenticated API returned six real panels and positive traffic; **a populated browser panel is not claimed**. The Service selector drill actually produced 200→502 with zero endpoints→200; the initial instrumentation error and successful finally-restoration remain retained.

## Genuine Terminal evidence

The PNGs below are original native window captures. The snapshot image explicitly displays a saved actual API result, with its original capture time; it is not presented as a fresh query after teardown. No terminal/browser screenshot was fabricated. Discarded partial screenshots were excluded from this deliverable.

| Capture | Meaning |
|---|---|
| [terraform-plan-terminal.png](terraform-plan-terminal.png) | Actual saved frozen plan summary while the genuine apply was in progress. |
| [terraform-apply-terminal.png](terraform-apply-terminal.png) | Actual completed 62-create output and real ACTIVE EKS/node-group responses. |
| [cloud-delivery-terminal.png](cloud-delivery-terminal.png) | Completed green CI/promotion records plus actual deployed full-SHA image queries. |
| [cloud-snapshot-terminal.png](cloud-snapshot-terminal.png) | Explicitly saved real pre-teardown API snapshot; original capture time/source shown. |
| [cloud-runtime-during-scale-up-terminal.png](cloud-runtime-during-scale-up-terminal.png) | Actual kubectl output during growth: two Ready API Pods plus two starting; not steady state. |
| [cloud-scaling-terminal.png](cloud-scaling-terminal.png) | Real bounded load results including failures, lower-rate recovery and two-replica cooldown. |
| [cloud-verification-terminal.png](cloud-verification-terminal.png) | Explicitly saved actual runtime, CRUD, Service fault/recovery and target results. |
| [terraform-destroy-terminal.png](terraform-destroy-terminal.png) | Actual completed destroy output and recorded post-removal verification. |

[Supporting native cloud Terminal recording](cloud-terminal-walkthrough.mp4) shows real queries/completed records, including query waiting time. It has no browser or audio and is not the full student live presentation. The original recording is retained privately; exact hashes and capture limits are recorded separately.

## Original results and retained failures

| File | Meaning |
|---|---|
| [cloud-api-inventory.json](cloud-api-inventory.json) | Actual ACTIVE EKS/node group, four subnets and five add-ons after the 62-create apply. |
| [cloud-runtime-initial-5cb1c80.json](cloud-runtime-initial-5cb1c80.json) | Initial genuine cloud runtime on the earlier green 5cb1c80 images. |
| [cloud-runtime.json](cloud-runtime.json) | Actual post-promotion 06909ce Pods/images, Services, bound gp3 and healthy public NLB. |
| [controller-fix-ci-green.json](controller-fix-ci-green.json) | Public API metadata: all seven fresh CI jobs succeeded for exactly 06909ce. |
| [cloud-ci-promotion.json](cloud-ci-promotion.json) | Actual successful Helm rollout from 5cb1c80 to the green 06909ce SHA. |
| [anonymous-image-access.json](anonymous-image-access.json) | Actual anonymous multiarch manifest access for 5cb1c80; no bearer tokens saved. |
| [anonymous-image-access-06909ce.json](anonymous-image-access-06909ce.json) | Actual anonymous amd64/arm64 manifest access for the promoted 06909ce images. |
| [cloud-crud.json](cloud-crud.json) | Real NLB POST 201, GET/PUT 200, overdue/return counters, DELETE 204 and GET 404; baseline restored. |
| [cloud-demo-fixtures.json](cloud-demo-fixtures.json) | Three explicitly fictional records actually created afterward for the UI capture. |
| [cloud-database-tables.txt](cloud-database-tables.txt) | Actual cloud PostgreSQL table/count check with default_transaction_read_only=on. |
| [cloud-nonroot-users.json](cloud-nonroot-users.json) | Actual container identities: backend 10001 and frontend 101. |
| [cloud-storage.json](cloud-storage.json) | Actual encrypted 2GiB gp3 volume and Delete reclaim policy, recorded before cleanup. |
| [cloud-monitoring.json](cloud-monitoring.json) | Actual unfiltered Prometheus inventory: 16 UP/0 DOWN at the recorded baseline time. |
| [cloud-grafana-data.json](cloud-grafana-data.json) | Authenticated real six-panel Grafana API/traffic proof; not a populated browser screenshot. |
| [cloud-service-drill.json](cloud-service-drill.json) | Actual Service selector fault: 200→502/zero endpoints→200 after exact restoration. |
| [cloud-service-drill-initial-attempt.json](cloud-service-drill-initial-attempt.json) | Initial EndpointSlice-null instrumentation failure; finally-restoration succeeded; retained separately. |
| [cloud-bounded-load.json](cloud-bounded-load.json) | Actual 90-second burst: 7,431 HTTP 200, 12 failures; HPA reached four Ready API Pods. |
| [cloud-post-load-recovery.json](cloud-post-load-recovery.json) | Separate lower-rate recovery: 40/40 HTTP 200, followed by observed HPA cooldown to two. |
| [ingress-install-schema-timeout-1.txt](ingress-install-schema-timeout-1.txt) | First real external JSON-schema fetch timeout; no controller install claimed. |
| [ingress-install-schema-timeout-2.txt](ingress-install-schema-timeout-2.txt) | Second real external schema timeout, retained without suppressing the failure. |
| [ingress-offline-schema-validation.json](ingress-offline-schema-validation.json) | Pinned upstream schema, 82 local references, identical runtime manifests, validation enabled. |
| [controller-duplicate-port-failure.txt](controller-duplicate-port-failure.txt) | Real server-side apply rejection of duplicate 8081/TCP controller ports. |
| [controller-port-fix.json](controller-port-fix.json) | Readiness preserved; optional duplicate-producing controller startup probe disabled. |
| [swagger-loopback-recovery.json](swagger-loopback-recovery.json) | Actual repair of the existing backend port-forward; HTTP200 and Swagger HTML verified. |
| [kubernetes-cleanup.json](kubernetes-cleanup.json) | App/PVC/EBS deletion verified before CSI/node permissions were removed. |
| [cloud-cleanup-verification.json](cloud-cleanup-verification.json) | Actual 62-resource destroy, zero managed state, exact cloud absence checks and new-only service-role cleanup. |
| [new-service-linked-role-cleanup.json](new-service-linked-role-cleanup.json) | Exact baseline/create-time checks and direct GetRole absence verification for all three proven-new automatic roles. |
| [terminal-plan-provenance.json](terminal-plan-provenance.json) | Original native saved-plan screenshot checksum and scope. |
| [terminal-apply-provenance.json](terminal-apply-provenance.json) | Original native actual-apply/EKS/node-group screenshot checksum and scope. |
| [native-capture-provenance.json](native-capture-provenance.json) | Original native Terminal screenshots, hashes, timestamps and saved-result labels. |
| [cloud-video-provenance.json](cloud-video-provenance.json) | Native Terminal-window-only recording, original/published hashes; no browser or audio. |

## Browser and presentation limits

Seven genuine personal-profile Console/app/Prometheus images were reviewed privately. They include account/resource identifiers and remain outside this publication pending their specific approval. No private browser pixels were embedded in the published deck. Grafana login and the full student browser/live walkthrough remain separate requirements. Swagger forwarding was repaired and HTTP 200 verified before retirement; the earlier failed screen is preserved privately. No additional form action or instructor acceptance is claimed.

The aggregate service-role deletion-request flags were reconciled with the separate guarded cleanup responses; all three requests and direct absence checks are recorded. This documentation correction made no new AWS calls.
