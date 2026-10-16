# Local validation record — 16 October 2026

Executed on the user's Mac with Terraform **1.15.8**, `darwin_arm64`.

| Check | Observed result |
|---|---|
| `terraform init -backend=false -input=false` | Succeeded; downloaded signed HashiCorp AWS provider **6.18.0**; generated `.terraform.lock.hcl` |
| `terraform fmt -check -recursive` | Passed |
| `terraform validate -no-color` | `Success! The configuration is valid.` |
| `terraform test -no-color` | **6 passed, 0 failed**, all using `mock_provider "aws"` |

Mock tests verify: two public/two private subnets; NAT and ingress explicit opt-ins; private API retained with approved narrow public CIDRs; no automatic creator admin; encrypted worker root volume and IMDSv2; namespace-scoped operator and deliberate bootstrap admin; rejection of Internet-wide public API, admin without identity, and unreviewed node growth.

Mock plan resource counts were observed with `terraform test -verbose`: **49** additions for public-node defaults with one API CIDR/no operator/no app audience; **56** for NAT/private nodes with one namespace operator and one app-client CIDR; **52** for public nodes with one operator and bootstrap grant/no app audience. These are **mock graph checks, not real AWS plans**. Proposed NAT/private mode with one operator, bootstrap grant and one app-client CIDR would contain **57** Terraform resource instances. Kubernetes-created load balancers/PVs and AWS-created supporting resources are additional.

The provider now also requires an exact `approved_account_id`, enforced with `allowed_account_ids`. The example account/address are intentionally documentation-only placeholders. No AWS STS, account plan, apply, destroy, Console operation, existing AWS profile or account credentials were used during these checks. Provider package retrieval is not an AWS account action. No public app endpoint, successful deployment, cloud screenshot, teardown, or AWS cost is claimed.

Real AWS non-empty plan, apply, running EKS/Helm/monitoring and destroy evidence remain pending explicit sandbox, resource/access, current price/cap/duration and project-only teardown approvals. The root evidence log should record those only if actually completed.
