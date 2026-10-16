# Rubric implementation and evidence status

This is a status map, not a self-awarded grade. The instructor decides marks. The current verified rubric has 100 points across ten modules.

| Module | Weight | Implemented / actually verified | Remaining evidence or dependency |
|---|---:|---|---|
| M1 Application | 10 | Original equipment-loan UI/API, PostgreSQL/Alembic, actual Compose stack, real HTTP CRUD/readiness/metrics checks | Genuine SST-profile desktop/mobile/dialog captures verify final UI; see browser review |
| M2 Testing | 10 | 35 isolated API/migration tests passed; separate actual PostgreSQL runtime checks; configured pytest | Native Terminal captures show all 35 actual completed CI test results across two images; no rerun was claimed |
| M3 Git/GitHub | 5 | Public repository with at least 17 meaningful commits; secrets/dependencies ignored; actual green CI | Native Terminal history capture shows 12 meaningful commits |
| M4 Docker | 10 | Both images built and ran as non-root; real 3-service startup; data survived backend replacement | Current Compose health/non-root/read-only table capture complete; final localhost:3000 browser capture pending |
| M5 CI/CD | 15 | Main-triggered test/build/strict-scan/multi-architecture SHA-publication workflow implemented | First actual remote run green; full-SHA multiarch images published. Browser package-page capture/access visibility pending |
| M6 DevSecOps | 5 | Strict scan found Debian OS issues; Alpine replacement and final frontend have 0 HIGH/CRITICAL in local scans | Native capture of actual completed CI scan output/strict flags and four-report clean summary complete; no gate suppressed |
| M7 Terraform/AWS | 15 | Signed provider init, HCL validation/format and 9 mock-provider tests passed; account guard; verified personal identity and real 62-create read-only plan | Exact access/bootstrap/network/teardown approval pending; no apply, real VPC/EKS runtime, Console or destroy evidence yet |
| M8 Kubernetes/Helm | 15 | Chart lint/semantic checks and actual local install; 2 UI / 2 API / PostgreSQL ready, Ingress request200 | Current native Pods/Services/Helm capture complete; actual prior HPA 2→4 Ready→2 and Service repair 200→503→200 retained |
| M9 Observability | 10 | Endpoint exposes real metrics; Prometheus/Grafana configuration and matching dashboard written | Both targets UP, real PromQL data, six-panel Grafana dashboard verified through authenticated API; final browser screenshot pending |
| M10 Docs/demo | 5 | Root setup/runbooks; actual change→green CI→exact-SHA local rollout; 12-slide PDF/editable PPTX with notes; genuine 53-second Terminal recording | Full live/recorded browser walkthrough and post-promotion browser capture remain; Terminal recording is supporting evidence, not a full demo |

Read [the evidence index](../evidence/README.md) for the latest actual results. Configuration files, planned commands and expected screenshots never substitute for a real run. Missing screenshots/remote/cloud operations remain explicitly pending until captured.
