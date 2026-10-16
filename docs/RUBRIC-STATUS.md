# Rubric implementation and evidence status

This is an evidence map, not a self-awarded grade. The instructor decides marks.

| Module | Weight | Actually implemented / verified | Remaining evidence or limit |
|---|---:|---|---|
| M1 Application | 10 | Original equipment-loan UI/API, actual PostgreSQL/Alembic, local and public AWS CRUD/status counters | Three cloud UI fixtures are explicitly fictional; private browser originals await publication approval |
| M2 Testing | 10 | 35 isolated API/migration and 9 frontend tests in the unchanged suites; fresh 06909ce CI test jobs succeeded | Original 35-result native captures are historical completed CI output, not a fresh local rerun |
| M3 Git/GitHub | 5 | Public personal repository; meaningful history; exact source SHA and CI/promotion records | Later documentation-only commits are distinct from tested image revision 06909ce |
| M4 Docker | 10 | Real three-service Compose; actual cloud UIDs 10001/101 and persistent PostgreSQL | Earlier browser evidence is separate from private final refresh images |
| M5 CI/CD | 15 | Seven fresh green jobs, four strict scan gates, actual anonymous multiarch SHA manifests and guarded EKS promotion | CI publishes images; cloud promotion is an explicit step, not automatic AWS access |
| M6 DevSecOps | 5 | Original failed Debian scan retained; Alpine repair; current four strict scan jobs succeeded | Earlier raw reports retained; fresh 06909ce raw report ZIPs were not downloaded |
| M7 Terraform/AWS | 15 | Real 62-create apply, ACTIVE VPC/EKS/node group, actual runtime, ordered PVC/EBS cleanup, 62-delete destroy and post-removal verification | Console originals captured/reviewed privately but unpublished pending specific approval; final AWS bill not yet verified |
| M8 Kubernetes/Helm | 15 | Two Ready UI/API baseline; real HPA 2 → 4 Ready → 2; bound encrypted gp3; actual Service 200→502→200 | Burst 7,431 HTTP 200 / 12 failures retained; separate lower-rate recovery 40/40; single worker is not HA |
| M9 Observability | 10 | Actual 16/16 UP baseline; real six-panel Grafana authenticated API and positive traffic | Populated Grafana browser screenshot remains pending; API evidence is not that screenshot |
| M10 Docs/demo | 5 | Setup/runbooks, real CI→exact-SHA local/cloud rollouts, 12-slide PDF/editable PPTX/notes, original Terminal evidence and supporting recordings | Full student browser/live presentation and specifically authorized browser-image publication remain separate |

See [actual cloud evidence](../evidence/aws-live-2026-10-16/README.md) and the [evidence index](../evidence/README.md). Configuration, expected screenshots and planning do not substitute for actual results. The temporary cloud environment is retired; local reproduction remains available.
