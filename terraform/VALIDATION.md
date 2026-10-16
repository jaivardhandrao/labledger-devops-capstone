# Local and read-only account validation — 16 October 2026

Executed on the user's Mac with Terraform **1.15.8**, `darwin_arm64`.

| Check | Observed result |
|---|---|
| `terraform init -backend=false -input=false` | Succeeded; downloaded signed HashiCorp AWS provider **6.18.0**; generated `.terraform.lock.hcl` |
| `terraform fmt -check -recursive` | Passed |
| `terraform validate -no-color` | `Success! The configuration is valid.` |
| `terraform test -no-color` | **6 passed, 0 failed**, all using `mock_provider "aws"` |

Mock tests verify: two public/two private subnets; NAT and ingress explicit opt-ins; private API retained with approved narrow public CIDRs; no automatic creator admin; encrypted worker root volume and IMDSv2; namespace-scoped operator and deliberate bootstrap admin; rejection of Internet-wide public API, admin without identity, and unreviewed node growth.

Mock plan resource counts were observed with `terraform test -verbose`: **49** additions for public-node defaults with one API CIDR/no operator/no app audience; **56** for NAT/private nodes with one namespace operator and one app-client CIDR; **52** for public nodes with one operator and bootstrap grant/no app audience. These are **mock graph checks, not real AWS plans**. Proposed NAT/private mode with one operator, bootstrap grant and one app-client CIDR would contain **57** Terraform resource instances. Kubernetes-created load balancers/PVs and AWS-created supporting resources are additional.

The provider now also requires an exact `approved_account_id`, enforced with `allowed_account_ids`. The example account/address are intentionally documentation-only placeholders. No AWS STS, account plan, apply, destroy, Console operation, existing AWS profile or account credentials were used during the initial local/mock checks described above. Subsequent authorized read-only account work is recorded below. Provider package retrieval is not an AWS account action. No public app endpoint, successful deployment, cloud screenshot, teardown, or AWS cost is claimed.

Real AWS non-empty plan, apply, running EKS/Helm/monitoring and destroy evidence remain pending explicit sandbox, resource/access, current price/cap/duration and project-only teardown approvals. The root evidence log should record those only if actually completed.

The final source/runbook audit aligned the unapplied disposable `gp3` StorageClass example to reclaim policy `Delete`. This does not delete data or modify any cluster. The runbook now distinguishes Helm uninstall (StatefulSet PVC retained) from deliberate approved project-PVC deletion (CSI deletes its backing EBS volume). Existing StorageClasses/PVs are not automatically changed. Real account, resource, data-disposal and teardown approval remains pending.

AWS bootstrap is also still pending: finalize and verify an Ingress Controller, the selected load-balancer mode/IAM, fixed NodePorts/health checks and Metrics Server before claiming cloud readiness. The working local classroom controller/Metrics Server are not evidence that those components are installed on AWS. This audit made no AWS, network, Kubernetes or Git calls.

## Subsequent authorized read-only account review

After the user supplied personal-file credentials and root verified their identity, an isolated credential-chain environment produced a real **56-create** baseline plan, with documentation CIDRs and no bootstrap admin. That historical binary stays private and must not be applied. The coordinator then verified the actual operator egress /32; a second **proposed** plan produced **62 creates, zero updates and zero deletes** with real privately held API/32, explicit proposed public synthetic HTTP audience, Terraform-owned NLB, managed Metrics Server and proposed temporary new-cluster admin association. **No apply/create/grant/destroy occurred.** This second plan requires human action-time confirmation; its full identity, IP and binary hash stay in a private action review outside public Git.

Official AWS Price List GetProducts supplied Mumbai rates and a transparent two-hour **$2.432349 before-tax** review scenario including25% contingency. EKS DescribeClusterVersions verified1.34 STANDARD_SUPPORT until2December2026. DescribeAddonVersions/Configuration verified managed Metrics Server `v0.9.0-eksbuild.13`, no IAM permission requirement and container port10251. These were permitted read-only API calls using only the supplied personal credentials. Ordinary web/controller research remains in School Chrome.

Updated source passed `terraform validate`, recursive format checks and **nine mock tests**. The three added tests cover NLB TCP80→instance NodePort30080/ASG attachment, dedicated SG routing without direct-node CIDR exposure, explicit app audience and conditional managed Metrics Server/10251 path. Existing six baseline tests still pass with optional features disabled. See the [review worksheet](../docs/AWS-REVIEW-PLAN.md), [redacted proposed inventory](../docs/AWS-READONLY-PLAN-SUMMARY.json) and [official SKU/rate calculations](../docs/AWS-PRICING-2026-10-16.json). No live cloud deployment/scan/dashboard/teardown evidence is inferred from these plans.
