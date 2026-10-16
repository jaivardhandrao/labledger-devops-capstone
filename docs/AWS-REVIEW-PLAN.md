# AWS review plan — read-only account plan, no deployment

**Status on 16 October 2026:** the user subsequently supplied personal AWS credentials and authorized project work. The supplied identity was verified through STS and isolated from all workplace credential/profile sources. The user accepted the conditional **ap-south-1 / US$10 / maximum two-hour** proposal. An initial read-only account plan produced 56 creates without bootstrap admin; a revised proposed plan produced **62 creates, zero updates and zero deletes** with Terraform-owned HTTP NLB, managed Metrics Server and proposed temporary bootstrap admin. **No plan has been applied and no resource, access grant or cloud spending has been initiated.** The exact IAM/account/IP and binary plan hash are held in a private action review outside Git, not this public document.

The revised plan still requires explicit action-time confirmation of the four service IAM roles, EKS IRSA provider, temporary cluster-admin grant, controller Kubernetes RBAC, new network rules/public synthetic HTTP and project-only data disposal/teardown. A supplied credential is not a record that those changes happened. Workplace accounts/profiles remain prohibited. The old documentation-CIDR plan is historical and must not be applied.

Official AWS Price List APIs supplied the rates below; the reviewed illustrative total is **$2.432349 before tax**, including 25% contingency, within the conditional $10 proposal. This is an estimate with stated usage assumptions, not a guaranteed bill or automated spending cutoff. Ordinary web/controller research stays in the required School Chrome profile.

## Proposed deployment to review

- Region: `ap-south-1` (Mumbai), AZs `ap-south-1a` and `ap-south-1b`, subject to actual account availability.
- One disposable EKS cluster, one managed node group with **one `t3.large` Linux On-Demand worker**, min/desired/max = 1; encrypted **20 GiB gp3** root disk. A single worker is not highly available. Do not perform a node/AMI upgrade during this bounded demo: managed replacement capacity can temporarily exceed the desired count.
- Two public and two private subnets in one new project VPC. Worker in a private subnet; **one NAT gateway and one EIP** in a public subnet. One NAT is not AZ-resilient and may incur cross-AZ data charges.
- Optional Terraform-owned **one public IPv4 NLB**, cross-zone enabled in the two public subnets, TCP80 listener to instance NodePort30080, with an ASG target attachment. A dedicated NLB SG admits the explicitly reviewed app audience; worker SG admits that traffic only from the NLB SG. No AWS Load Balancer Controller or fifth service role is needed. Install the separately reviewed supported NGINX controller as NodePort, not a second LoadBalancer Service. Only synthetic demo data may be public over this HTTP endpoint.
- App: two frontend/two backend replicas; HPA may grow backend Pods to four, not worker nodes. One PostgreSQL PVC requests **2 GiB**; proposed disposable EBS class is encrypted gp3 with `Delete` reclamation. Monitoring currently uses ephemeral storage; no monitoring EBS PVC is included in this minimum proposal.
- Public Kubernetes API restricted to the approved operator's real IPv4 `/32` (the source accepts only `/24`–`/32`); private API remains enabled. No SSH key or inbound port 22. App audience is approved separately and does not open the API.
- The proposed review uses a privately verified operator /32 and proposes public app clients on NLB80 separately. Exact private inputs are not published. Source defaults and documentation IP/account values are not an executable deployment configuration. Review [Terraform inputs](../terraform/terraform.tfvars.example) and [the detailed runbook](../terraform/README.md).

## Exact revised proposed plan: 62 creates

This is an **actual read-only account plan**, not only a mock graph. It proposes NAT, one operator/API CIDR, public synthetic app audience at NLB80, the explicit temporary bootstrap-admin association, Terraform-owned NLB and managed Metrics Server. It remains **unapproved for apply**. No account ID, real operator IP, ARN, credential, raw state or binary plan is included in public evidence.

| Planned Terraform-managed set | Creates |
|---|---:|
| VPC, Internet gateway, four subnets, two route tables, four route associations, two routes, NAT/EIP | 16 |
| Three security groups and seventeen rule resources | 20 |
| Four service IAM roles, five managed-policy attachments, one EKS IRSA OIDC provider | 10 |
| EKS control plane, managed node group, launch template, five managed add-ons | 8 |
| NLB, TCP listener, instance target group, managed-worker ASG target attachment | 4 |
| CloudWatch log group | 1 |
| Operator access entry, namespace edit association, proposed temporary cluster-admin association | 3 |
| **Total** | **62** |

See [redacted account-plan inventory](AWS-READONLY-PLAN-SUMMARY.json). The earlier 57-instance worksheet assumed an external LB and no managed Metrics Server, so it is superseded by this 62-create proposal. AWS creates supporting EC2/root EBS/Auto Scaling/ENI/service-linked resources; a later app Helm deployment creates its PostgreSQL volume. These supporting objects are not additional standalone Terraform source resources. The plan has no existing managed resources to update/delete, but it does not assert that the whole account has no unrelated resources.

## Verified official rate worksheet

Rates were retrieved on **16 October 2026** using official **AWS Pricing GetProducts** at the us-east-1 API endpoint, selecting ap-south-1/Mumbai product attributes and On-Demand dimensions. [Machine-readable rates and official SKUs](AWS-PRICING-2026-10-16.json) preserve exact descriptions, units and effective dates (August–October 2026). These are API observations; linked pricing pages are reference destinations, not a claim of browser inspection. No free-tier benefit is assumed.

| Input | Verified USD rate | Official reference |
|---|---:|---|
| EKS standard-support cluster | $0.10/hour | [EKS pricing](https://aws.amazon.com/eks/pricing/) |
| Linux shared-tenancy On-Demand t3.large | $0.0896/hour | [EC2 pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| Zonal NAT gateway | $0.056/hour + $0.056/GB processed | [VPC pricing](https://aws.amazon.com/vpc/pricing/) |
| In-use public IPv4 | $0.005/address-hour | [IPv4 pricing](https://aws.amazon.com/vpc/pricing/) |
| Network Load Balancer | $0.0239/hour + $0.006/NLCU-hour | [ELB pricing](https://aws.amazon.com/elasticloadbalancing/pricing/) |
| gp3 storage | $0.0912/GB-month | [EBS pricing](https://aws.amazon.com/ebs/pricing/) |
| Standard Logs ingestion / storage | $0.67/GB + $0.03/GB-month stored | [CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/) |
| Linux T3 surplus CPU credits, if billed | $0.05/vCPU-hour | [EC2 pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| First paid Internet egress tier | $0.1093/GB | [Transfer pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| Regional transfer where charged | $0.01/GB per billed leg | [Transfer pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |

Read-only EKS APIs confirmed Kubernetes **1.34 is STANDARD_SUPPORT**, ending **2 December 2026**, and Metrics Server **v0.9.0-eksbuild.13** is compatible/default for 1.34, requires no AWS IAM permission and listens on **10251**. The source explicitly opens that control-plane path only when this add-on is enabled. EKS Auto Mode/provisioned-tier prices were excluded; this source uses a standard cluster plus a managed node group.

### Two-hour review scenario

Assume two billable hours for each hourly resource; one worker, one NAT, one NLB; three public IPv4 addresses (NAT plus two enabled LB AZ allocations); and 22 GB gp3 total (20 root + 2 PostgreSQL). Storage uses a **730-hour normalized month for estimation**, not a claim about exact invoice precision. Setup/teardown time and minimum/partial-hour billing must fit the window.

| Component / explicit review assumption | Estimated USD |
|---|---:|
| EKS 2h, EC2 2h, NAT 2h, NLB 2h, 6 IPv4-address-hours, 22 GB gp3 for 2h | 0.574497 |
| 5 GB NAT processing | 0.280000 |
| 2 NLCU-hours | 0.012000 |
| 1 GB standard log ingestion + 1 GB stored for 2h | 0.670082 |
| 1 GB Internet egress, no free tier | 0.109300 |
| 5 GB cross-AZ counted on two billed legs | 0.100000 |
| Up to 4 surplus Linux T3 vCPU-hours | 0.200000 |
| **Subtotal before tax** | **1.945879** |
| 25% contingency | 0.486470 |
| **Reviewed illustrative total before tax** | **2.432349** |

A rounded **$3 before tax** is a planning reserve, not a hard ceiling. Verify applicable taxes, exact NLB address/billing model and bounded usage before action-time approval. No traffic or AWS bill was observed; these are transparent scenario quantities, not fabricated measurements. More downloads, log volume, CPU credits, replacements, persistent data or delayed deletion change the result. Cross-AZ waivers/credits are not assumed. The selected API rate details make the arithmetic reproducible.

AWS Budgets/alerts do not enforce a guaranteed hard spending cutoff. The user-approved conditional bounds remain **$10 total / at most two hours**, including creation/teardown; begin cleanup early enough to verify deletion. No budget enforcement or cloud watchdog has been created by this document.

## Account, IAM and network prerequisites

| Dependency | Required review before execution |
|---|---|
| Eligible account | A personal-file IAM-user identity is now verified; the exact account/ARN stays private. Confirm this exact target again at action time; never use workplace staging/production profiles. `approved_account_id` must match and is enforced by the AWS provider. |
| Provisioning permissions | Review the execution role's exact VPC/EC2/EKS/IAM/CloudWatch creation, tagging and project teardown rights, including required `iam:PassRole` and service-linked-role behavior. No credentials are placed in Terraform, Git, screenshots or chat. No broad administrator policy is proposed as a shortcut. |
| EKS service roles | Four proposed service roles: EKS control plane, worker node, VPC CNI and EBS CSI; none has been created. Five purpose-specific AWS-managed attachments are listed in [Terraform README](../terraform/README.md). No application Pod gets an AWS role. |
| Service-account IRSA | One OIDC provider for **this EKS cluster's issuer**; CNI/EBS role trust requires the exact `kube-system` service account and `sts.amazonaws.com` audience. Review actual issuer/ARN in the eventual plan. |
| Operator access | Name the exact IAM role/user. Creator-admin is disabled. Namespace edit is limited to `labledger`; temporary cluster admin for namespaces/controllers/CRDs is a separate explicit flag/approval. Keep the approved temporary bootstrap access through all Kubernetes cleanup, then destroy the association with the project; do not add a persistent teardown grant. |
| Post-bootstrap deployment | Current scripts reapply the namespace and may create a ServiceMonitor in `monitoring`; an editor limited to `labledger` cannot do those operations after admin revocation. Finalize an appropriately scoped bootstrap/deployment procedure before AWS execution; do not silently broaden access. Cluster-scoped checks also require appropriate read rights. |
| API network path | Replace documentation CIDR with the operator's approved real egress; private API is enabled. Dynamic GitHub-hosted runner addresses are not added to the API allowlist by this plan. |
| Ingress/LB | Review the pinned supported NGINX NodePort controller/RBAC. Terraform proposes a cross-zone instance-target NLB, TCP80 to30080, TCP traffic-port health checks, dedicated SG references and an explicit public synthetic-demo audience. No second LoadBalancer Service or AWS LB-controller role. Verify real targets before claiming ingress works. |
| Metrics and persistence | Review/enable the API-verified optional managed Metrics Server add-on and verify HPA after deployment. Confirm EBS CSI is active, apply the reviewed disposable StorageClass, and select `database.storage.className=gp3`. Check actual PVC binding/zone constraints. Local controller/metrics/storage success does not verify EKS. |

### GitHub OIDC is optional and excluded

**EKS service-account IRSA is not GitHub Actions OIDC.** The 62-create proposal contains the EKS issuer and CNI/CSI service-account roles only. It creates no GitHub OIDC provider, no Actions deployment role and no persistent AWS permission for CI. The existing publication workflow uses the ephemeral repository GitHub token for GHCR, which is not an AWS credential.

Any future Actions-to-AWS integration needs a separate trust policy restricted to the exact repository/ref or protected environment, reviewed deployment permissions, API reachability and approval. Its IAM objects/cost/security implications are outside this proposal. Do not add long-lived AWS keys to GitHub secrets or claim this plan includes automatic cloud deployment.

## Controlled execution and teardown, only after dependencies are met

1. Record the eligible account/role, current price worksheet, approved resource/IAM/network scope, start time, stop time and project-only deletion authorization. An account identity is now verified, but **stop before apply/grants until the exact private action review is confirmed**.
2. Use only that approved identity to verify caller/account; review the already generated non-empty proposed plan; regenerate and re-review if the source, identity, operator IP or selected scope changes. Inspect all create/change/destroy actions and retain a redacted real plan screenshot. Mock checks do not satisfy the rubric's account-plan requirement.
3. Apply the exact reviewed plan, configure the explicit project Kubernetes context, bootstrap the finalized controllers/metrics/storage and install SHA-tagged images. Record actual AWS region/resources, application, Pods/Services/Helm, monitoring and update evidence. Do not label placeholder plans or local screenshots as AWS evidence.
4. Before deleting anything, preserve approved evidence and back up any wanted app data. Confirm project context/account/state. Helm uninstall retains PostgreSQL StatefulSet PVCs. After deliberate project-data disposal approval, delete only this project's disposable PVCs; the `Delete` policy/CSI driver removes backing EBS volumes. Existing PVs do not inherit a changed StorageClass policy retroactively.
5. Keep CSI/LB controllers alive until their managed volumes, LBs and finalizers have finished deleting. Verify the PostgreSQL EBS volume is gone before removing its CSI driver. This NLB is Terraform-owned; preserve its planned ownership and let the reviewed destroy remove the NLB/listener/target attachment. Verify no extra Kubernetes-created LB exists. Review leftover retained resources rather than deleting unrelated objects.
6. Review a real project-only destroy plan, apply that approved plan, capture successful completion and verify the relevant account/region contains no project EKS worker, NAT/EIP, LB or orphan EBS data volume. Terraform tracks this proposed NLB but not the Kubernetes-created app PV; check for any unplanned Kubernetes-created LB too. A local empty state does not prove cloud cleanup.
7. Record actual end time, deletion verification and any remaining charges/resources. If cleanup fails, report exact project resource IDs and the failure; do not expand access or delete shared resources to force success.

## What is ready and what is blocked

Source checks passed: signed AWS provider init, Terraform format/schema validation and **nine mock-provider tests**, including optional NLB security/wiring and managed Metrics Server paths. Two actual read-only account plans were generated; neither was applied. See [validation record](../terraform/VALIDATION.md). The local application/cluster evidence is indexed separately under [evidence](../evidence/README.md).

**Still pending:** explicit action-time confirmation of the reviewed IAM/network/controller/bootstrap and project-only teardown/data-disposal scope; actual apply/runtime/Console/destroy evidence. Pricing and read-only plans are now observed. No charged resource, public exposure, access grant, deployment success or full rubric credit is claimed.

## Automatic AWS service-linked roles — preflight clarification

Read-only IAM GetRole baseline found all three roles below **absent before any provisioning**. IAM GetPolicy verified each listed AWS-managed permission-policy ARN. The service principal/service name is the expected AWS service-linked-role trust target; no live trust document can be observed while its role is absent. These are **up to three automatic AWS-managed roles in addition to four explicit Terraform service roles**, outside the 62-resource Terraform state and unchanged binary plan. No role has been created. Their possible automatic creation must be included in action-time confirmation.

| AWS-managed role | Observed baseline | Expected AWS service principal | Verified permission-policy ARN |
|---|---|---|---|
| `AWSServiceRoleForAmazonEKS` | **Absent before provisioning** (`NoSuchEntity`) | `eks.amazonaws.com` | `arn:aws:iam::aws:policy/aws-service-role/AmazonEKSServiceRolePolicy` |
| `AWSServiceRoleForAmazonEKSNodegroup` | **Absent before provisioning** (`NoSuchEntity`) | `eks-nodegroup.amazonaws.com` | `arn:aws:iam::aws:policy/aws-service-role/AWSServiceRoleForAmazonEKSNodegroup` |
| `AWSServiceRoleForAutoScaling` | **Absent before provisioning** (`NoSuchEntity`) | `autoscaling.amazonaws.com` | `arn:aws:iam::aws:policy/aws-service-role/AutoScalingServiceRolePolicy` |

AWS EKS/managed node-group/Auto Scaling operations may automatically create these roles. Terraform destroy does **not** manage/delete them. Never delete a role that existed before this project or is used by another service/project. After all approved Kubernetes cleanup and Terraform resource destruction, project-only cleanup may request `DeleteServiceLinkedRole` **only** for a role recorded absent at baseline and proven newly created for this run, after verifying no remaining service dependencies. Let AWS enforce its dependency check, poll the deletion-task status, and stop/report any remaining usage or failure; do not override protection or detach policies to force deletion. Account-wide roles need special care if another workload begins using one during the demo. No service-linked-role deletion has been requested.

Keep the **already proposed temporary new-cluster admin association** until all approved Kubernetes app/PVC/controller/monitoring cleanup finishes. Then let the reviewed Terraform destroy remove that association with the cluster and other project resources within the two-hour window. This avoids revoking it early and later inventing another persistent teardown grant. No new grant is implied by this timing clarification.
