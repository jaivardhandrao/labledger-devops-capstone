# AWS review plan — no account, no cloud execution

**Status on 16 October 2026:** the student confirmed that no personal/school AWS account is available. The user accepted the **conditional ap-south-1 / US$10 / maximum two-hour** proposal and authorized preparing this review plan. That is not a ready-to-run cloud deployment: an eligible account, current verified prices, exact IAM/network choices and project-only teardown scope are still missing. **No workplace account/profile may be used.** No AWS STS, account plan, apply, deployment, Console or destroy operation has been performed. Existing completed deployment evidence is local.

This is an inventory and calculation worksheet. **It is not yet a costed quotation or execution approval.** The official rate inputs below remain pending research in the required School Chrome profile. Do not fill missing rates from memory or treat the budget as a guaranteed ceiling.

## Proposed deployment to review

- Region: `ap-south-1` (Mumbai), AZs `ap-south-1a` and `ap-south-1b`, subject to actual account availability.
- One disposable EKS cluster, one managed node group with **one `t3.large` Linux On-Demand worker**, min/desired/max = 1; encrypted **20 GiB gp3** root disk. A single worker is not highly available. Do not perform a node/AMI upgrade during this bounded demo: managed replacement capacity can temporarily exceed the desired count.
- Two public and two private subnets in one new project VPC. Worker in a private subnet; **one NAT gateway and one EIP** in a public subnet. One NAT is not AZ-resilient and may incur cross-AZ data charges.
- A proposed public app endpoint through **one load balancer** and an ingress controller, with exact controller, LB mode, enabled AZs, source-IP behavior and IAM still to be finalized. The Terraform graph does not create this LB.
- App: two frontend/two backend replicas; HPA may grow backend Pods to four, not worker nodes. One PostgreSQL PVC requests **2 GiB**; proposed disposable EBS class is encrypted gp3 with `Delete` reclamation. Monitoring currently uses ephemeral storage; no monitoring EBS PVC is included in this minimum proposal.
- Public Kubernetes API restricted to the approved operator's real IPv4 `/32` (the source accepts only `/24`–`/32`); private API remains enabled. No SSH key or inbound port 22. App audience is approved separately and does not open the API.
- The source defaults, documentation IP/account and empty access values are not an executable deployment configuration. Review [Terraform inputs](../terraform/terraform.tfvars.example) and [the detailed runbook](../terraform/README.md).

## What the 57 Terraform instances mean

This count assumes NAT enabled, **one** API CIDR, **one** app-client CIDR, one named operator and the explicitly approved temporary bootstrap-admin association. It is a local configuration/mock graph count, not an AWS inventory or actual account plan.

| Terraform-managed set | Instances |
|---|---:|
| VPC, Internet gateway, four subnets, two route tables, four route associations, two default routes, NAT and EIP | 16 |
| Two supplemental security groups and eighteen rule resources | 20 |
| Four service IAM roles, five managed-policy attachments, one EKS service-account OIDC provider | 10 |
| EKS control plane, managed node group, launch template and four managed add-ons | 7 |
| CloudWatch log group, seven-day retention | 1 |
| Operator access entry, namespace edit association, temporary bootstrap-admin association | 3 |
| **Total configured resource instances** | **57** |

AWS creates supporting EC2 instances, root volumes, Auto Scaling resources, ENIs, an EKS-managed cluster security group and service-linked roles where needed. Kubernetes may create the LB, its addresses and the PostgreSQL EBS volume. **57 does not mean 57 separately priced services, nor does it include all resulting cloud objects.** Removing bootstrap admin changes this source graph count; adding CIDRs/controller IAM changes it too. Review the actual non-empty account plan before any approved apply.

## Official price inputs still required

The following are official research destinations, not proof that their current regional prices were inspected. The School-profile browser worker must record the applicable **USD ap-south-1 rate, unit, support/usage tier, minimum billing rule and observation timestamp**. If a page delegates the rate to a calculator or SKU table, preserve that selection and source too. Include taxes and exchange conversion only if applicable; do not assume free-tier eligibility.

| Input | Quantity / chosen model | Verified current rate |
|---|---|---|
| EKS standard-support cluster-hour; confirm version `1.34` availability/support | 1 cluster; deployment window includes setup/teardown | **Pending** — [EKS pricing](https://aws.amazon.com/eks/pricing/) |
| EC2 Linux On-Demand `t3.large`, shared tenancy | 1 worker; include any billed CPU-credit surplus/replacements if applicable | **Pending** — [EC2 On-Demand pricing](https://aws.amazon.com/ec2/pricing/on-demand/) |
| NAT gateway-hour and processed GB | 1 NAT; registry/add-on downloads and demo traffic | **Pending** — [VPC pricing](https://aws.amazon.com/vpc/pricing/) |
| Public IPv4 address-hour | NAT EIP plus LB allocations; no worker public IP in private mode | **Pending** — [VPC public IPv4 pricing](https://aws.amazon.com/vpc/pricing/) |
| Chosen LB-hour and capacity/data units | Proposed 1 NLB; exact LB/controller decision still open | **Pending** — [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/) |
| gp3 storage duration, any billed provisioned performance | 20 GiB root + 2 GiB PostgreSQL minimum; no snapshots proposed | **Pending** — [EBS pricing](https://aws.amazon.com/ebs/pricing/) |
| Logs ingestion and storage | Five EKS control-plane log categories, actual generated bytes | **Pending** — [CloudWatch pricing](https://aws.amazon.com/cloudwatch/pricing/) |
| Cross-AZ/outbound data transfer and applicable taxes | Actual topology and bounded demo/download traffic | **Pending** — [EC2 transfer pricing](https://aws.amazon.com/ec2/pricing/on-demand/) and [VPC pricing](https://aws.amazon.com/vpc/pricing/) |

For two enabled Internet-facing LB AZs, review **two LB public IPv4 allocations plus the NAT EIP** as a starting allocation model; the selected LB's actual address model must be verified. Do not count only the NAT EIP. EKS cluster-hour and worker compute/storage are separate charges. EKS extended-support pricing must not be substituted unnoticed; confirm standard support before applying. The source requests `support_type=STANDARD`, which does not eliminate the need to review version lifecycle and upgrade behavior.

### Calculation worksheet

Let each `H_*` represent that resource's **actual billed duration** and each `r_*` its independently verified regional rate. Setup and deletion time count toward the two-hour operating window; billing granularity/minimums must follow the official rate sheet.

```text
C_base = H_eks × r_eks_standard
       + H_node × r_t3_large_linux_ondemand
       + H_nat × r_nat_hour
       + sum(allocated_IP_hours) × r_public_ipv4_hour
       + H_lb × r_selected_lb_hour

C_usage = NAT_GB × r_nat_GB
        + billed_LB_capacity_units × r_LB_capacity_unit
        + sum(each_gp3_GiB × official_duration_proration × r_gp3_GiB_month)
        + charged_EBS_performance_extras
        + CloudWatch_ingestion_and_storage
        + charged_cross_AZ_and_outbound_transfer
        + any_billed_CPU_credit_surplus_or_replacement_compute

C_review = C_base + C_usage + applicable_tax + reviewed_contingency
```

**No numerical total can be responsibly calculated until those rate and usage assumptions are filled.** Record a verified two-hour base, a bounded usage allowance and a contingency; proceed only if the total fits the approved **US$10** proposal and all other prerequisites are satisfied. If not, return the changed estimate/scope for review. Do not treat “two hours” alone as a cost estimate.

AWS Budgets/alerts are not a guaranteed hard spending cutoff. Delayed billing, teardown time, a failed create/delete, retained volumes, an unexpected LB or node replacement can exceed an intended budget. Begin cleanup early enough to verify deletion within the window; a deadline reminder alone is not resource teardown. No operational schedule or cloud watchdog has been created by this document.

## Account, IAM and network prerequisites

| Dependency | Required review before execution |
|---|---|
| Eligible account | Student/owner supplies an explicitly approved personal/school sandbox account and authorized credential-chain role; never borrow workplace staging/production profiles. `approved_account_id` must match and is enforced by the AWS provider. |
| Provisioning permissions | Review the execution role's exact VPC/EC2/EKS/IAM/CloudWatch creation, tagging and project teardown rights, including required `iam:PassRole` and service-linked-role behavior. No credentials are placed in Terraform, Git, screenshots or chat. No broad administrator policy is proposed as a shortcut. |
| EKS service roles | Four roles: EKS control plane, worker node, VPC CNI and EBS CSI. Five purpose-specific AWS-managed attachments are listed in [Terraform README](../terraform/README.md). No application Pod gets an AWS role. |
| Service-account IRSA | One OIDC provider for **this EKS cluster's issuer**; CNI/EBS role trust requires the exact `kube-system` service account and `sts.amazonaws.com` audience. Review actual issuer/ARN in the eventual plan. |
| Operator access | Name the exact IAM role/user. Creator-admin is disabled. Namespace edit is limited to `labledger`; temporary cluster admin for namespaces/controllers/CRDs is a separate explicit flag/approval. Verify authorized access before removing bootstrap access. |
| Post-bootstrap deployment | Current scripts reapply the namespace and may create a ServiceMonitor in `monitoring`; an editor limited to `labledger` cannot do those operations after admin revocation. Finalize an appropriately scoped bootstrap/deployment procedure before AWS execution; do not silently broaden access. Cluster-scoped checks also require appropriate read rights. |
| API network path | Replace documentation CIDR with the operator's approved real egress; private API is enabled. Dynamic GitHub-hosted runner addresses are not added to the API allowlist by this plan. |
| Ingress/LB | Finalize an approved pinned controller, LB type/target mode/IAM, fixed NodePorts `30080`/`30443`, TCP traffic-port health checks and explicit app audience. Current SG rules do not permit an arbitrary allocated health-check port. Verify real targets and source-IP path before claiming ingress works. |
| Metrics and persistence | Install/verify Metrics Server for HPA. Confirm EBS CSI is active, apply the reviewed disposable StorageClass, and select `database.storage.className=gp3`. Check actual PVC binding/zone constraints. Local controller/metrics/storage success does not verify EKS. |

### GitHub OIDC is optional and excluded

**EKS service-account IRSA is not GitHub Actions OIDC.** The 57-instance proposal contains the EKS issuer and CNI/CSI roles only. It creates no GitHub OIDC provider, no Actions deployment role and no persistent AWS permission for CI. The existing publication workflow uses the ephemeral repository GitHub token for GHCR, which is not an AWS credential.

Any future Actions-to-AWS integration needs a separate trust policy restricted to the exact repository/ref or protected environment, reviewed deployment permissions, API reachability and approval. Its IAM objects/cost/security implications are outside this proposal. Do not add long-lived AWS keys to GitHub secrets or claim this plan includes automatic cloud deployment.

## Controlled execution and teardown, only after dependencies are met

1. Record the eligible account/role, current price worksheet, approved resource/IAM/network scope, start time, stop time and project-only deletion authorization. No account currently exists, so **stop before this stage**.
2. Use only that approved identity to verify caller/account; generate a real non-empty Terraform plan. Inspect all create/change/destroy actions and retain a redacted real plan screenshot. Mock checks do not satisfy the rubric's account-plan requirement.
3. Apply the exact reviewed plan, configure the explicit project Kubernetes context, bootstrap the finalized controllers/metrics/storage and install SHA-tagged images. Record actual AWS region/resources, application, Pods/Services/Helm, monitoring and update evidence. Do not label placeholder plans or local screenshots as AWS evidence.
4. Before deleting anything, preserve approved evidence and back up any wanted app data. Confirm project context/account/state. Helm uninstall retains PostgreSQL StatefulSet PVCs. After deliberate project-data disposal approval, delete only this project's disposable PVCs; the `Delete` policy/CSI driver removes backing EBS volumes. Existing PVs do not inherit a changed StorageClass policy retroactively.
5. Keep CSI/LB controllers alive until their managed volumes, LBs and finalizers have finished deleting. Verify the project app LB/addresses and PostgreSQL volume are gone before removing controllers and invoking Terraform teardown. Review leftover retained resources rather than deleting unrelated objects.
6. Review a real project-only destroy plan, apply that approved plan, capture successful completion and verify the relevant account/region contains no project EKS worker, NAT/EIP, LB or orphan EBS data volume. Terraform alone does not track the Kubernetes-created LB/PVs. A local empty state does not prove cloud cleanup.
7. Record actual end time, deletion verification and any remaining charges/resources. If cleanup fails, report exact project resource IDs and the failure; do not expand access or delete shared resources to force success.

## What is ready and what is blocked

Local source checks already passed: signed AWS provider init, Terraform format/schema validation and **six mock-provider tests**. See [validation record](../terraform/VALIDATION.md). The local application/cluster evidence is indexed separately under [evidence](../evidence/README.md).

**Still blocked:** eligible account; verified current rate inputs and bounded total; exact IAM/network/bootstrap decisions; real AWS plan/apply/runtime/Console/destroy evidence. No AWS operation, spending, public exposure, execution success or full rubric credit is claimed by this review plan.
