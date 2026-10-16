# Rubric implementation and evidence status

This is a status map, not a self-awarded grade. The instructor decides marks. The current verified rubric has 100 points across ten modules.

| Module | Weight | Implemented / actually verified | Remaining evidence or dependency |
|---|---:|---|---|
| M1 Application | 10 | Original equipment-loan UI/API, PostgreSQL/Alembic, actual Compose stack, real HTTP CRUD/readiness/metrics checks | Genuine SST-profile desktop/mobile/dialog captures verify final UI; see browser review |
| M2 Testing | 10 | 35 isolated API/migration tests passed; separate actual PostgreSQL runtime checks; configured pytest | Genuine Terminal screenshot of tests |
| M3 Git/GitHub | 5 | Meaningful component-by-component local commits; secrets/dependencies ignored | Public repository approved and created; content push/CI and final history screenshot pending |
| M4 Docker | 10 | Both images built and ran as non-root; real 3-service startup; data survived backend replacement | Final Docker/Compose Terminal and localhost:3000 browser screenshots |
| M5 CI/CD | 15 | Main-triggered test/build/strict-scan/multi-architecture SHA-publication workflow implemented | Actual green remote run and published GHCR image pages after approved repository creation |
| M6 DevSecOps | 5 | Strict scan found Debian OS issues; Alpine replacement and final frontend have 0 HIGH/CRITICAL in local scans | Successful CI scan output and its screenshot; no scan gate is suppressed |
| M7 Terraform/AWS | 15 | Signed provider init, HCL validation/format and 6 mock-provider tests passed; approved-account guard | Student has no AWS account: real plan/VPC/EKS/Console/teardown evidence cannot be completed; review-only plan remains |
| M8 Kubernetes/Helm | 15 | Chart lint/semantic checks and actual local install; 2 UI / 2 API / PostgreSQL ready, Ingress request200 | Actual HPA scaled 2 to 4 Ready API pods and back; Service fault repaired 200→503→200; final Terminal captures pending |
| M9 Observability | 10 | Endpoint exposes real metrics; Prometheus/Grafana configuration and matching dashboard written | Both targets UP, real PromQL data, six-panel Grafana dashboard verified through authenticated API; final browser screenshot pending |
| M10 Docs/demo | 5 | Root setup/architecture/runbooks and demonstration guide | Actual commit→green pipeline→deployment update demonstration/recording |

Read [the evidence index](../evidence/README.md) for the latest actual results. Configuration files, planned commands and expected screenshots never substitute for a real run. Missing screenshots/remote/cloud operations remain explicitly pending until captured.
