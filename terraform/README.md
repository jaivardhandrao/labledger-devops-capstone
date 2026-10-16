# LabLedger AWS infrastructure

This directory describes the real-AWS portion of the capstone. **Source code, formatting and local validation are not evidence of an AWS deployment.** No account plan, apply or teardown is claimed here. Only the root coordinator records operations that actually happen.

## Decisions before any account action

1. The owner must approve a specific personal/school sandbox account and role. Existing work staging/production profiles are outside scope. Use the existing AWS credential chain; no keys are accepted in HCL, tfvars, commits, screenshots or logs. The required `approved_account_id` provider guard rejects any other account; the all-zero example is deliberately unusable for a real AWS operation.
2. Approve region `ap-south-1`, the resources below, a monetary cap, a maximum running duration and deletion of only this project's resources after recording evidence. Neither Terraform nor AWS Budgets automatically enforces a hard total spending cap. NAT, EKS and load-balancer creation can incur charges even if deployment later fails.
3. Verify **current official AWS prices** and EKS version availability before approving the estimate. A proposed operational limit discussed by the coordinator is **USD 10 / at most 2 hours**, not an approval, quotation or guaranteed charge ceiling.
4. Specify the actual administrator's egress IPv4 `/32` (or another approved narrow CIDR). `203.0.113.10/32` in the example is a documentation address and will not allow a real operator to connect.
5. Select the exact IAM role/user for Kubernetes access. No automatic cluster-creator admin is enabled. Namespace edit access cannot install namespaces, cluster-scoped CRDs, ingress controllers or observability operators. If the owner approves bootstrap privilege, explicitly set `grant_bootstrap_cluster_admin=true`, install those components, then revoke that association with the flag set to false. Do not disable the flag until a tested authorized operational access path remains.
6. Approve the application audience separately via `ingress_client_cidrs`. Public application access never implies a public Kubernetes API. Do not include actual user/student data in a public demo: this teaching application has no production identity/access layer.

## Resource inventory and scope

The proposed example uses one `t3.large` On-Demand worker with 20 GiB encrypted gp3 root disk, min/desired/max = 1, two AZs, and one NAT gateway. Replica count and HPA operate on Pods; node autoscaling is not installed. A single worker is a classroom tradeoff with no node-level high availability. Review actual available allocatable memory for Prometheus/Grafana before deployment.

| Resource | Count / purpose |
|---|---|
| VPC | 1 (`10.42.0.0/16` default), DNS enabled |
| Subnets | 2 public + 2 private across two AZs |
| Internet gateway | 1 |
| Route tables / associations | 2 / 4 |
| Routes | 1 public Internet route; 1 private NAT route when enabled |
| NAT gateway / Elastic IP | 1 / 1 when `enable_nat_gateway=true`; zero when false |
| Security groups created by this code | 2 (control-plane supplemental SG and worker SG); EKS additionally creates its managed cluster SG |
| Security group rule resources | 15 + number of API CIDRs + 2 × number of app-client CIDRs (see rule breakdown below) |
| EKS control plane | 1; two private control-plane subnets; private API on, public API CIDR-restricted |
| Managed node group / launch template | 1 / 1; example one worker, no SSH key, IMDSv2 required, metadata hop limit 1 |
| IAM service roles | 4: EKS cluster, worker nodes, VPC CNI IRSA, EBS CSI IRSA |
| IAM managed policy attachments | 5: `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryPullOnly`, `AmazonEKS_CNI_Policy`, `service-role/AmazonEBSCSIDriverPolicy` |
| IAM OIDC provider | 1, tied to this EKS issuer; CNI/EBS role trust constrained to their exact service account and `sts.amazonaws.com` audience |
| Managed EKS add-ons | 4: `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver` |
| CloudWatch log group | 1; all five EKS control-plane log categories, 7-day retention |
| Optional EKS operator access | 0 by default. Explicit principal adds 1 access entry + 1 namespace edit policy association; approved bootstrap adds 1 temporary cluster-admin association |

EKS/EC2 also create supporting ENIs, EC2 instances, Auto Scaling resources and AWS-managed service-linked roles as needed. The node-group resource manages its EC2 infrastructure. This code does not create a GitHub OIDC provider/role, cluster autoscaler, RDS, Route 53 zone, custom domain, certificate, Kubernetes load balancer, monitoring PVCs or app PVCs. Helm/Kubernetes may create billable load balancers and volumes later; include those in the same approval and cost review, and delete them **before** Terraform teardown.

Security rule breakdown: API from workers (1), approved operator CIDRs (N), control plane outbound to nodes (4), nodes inbound from control plane (4), node-to-node Pod traffic (1), node outbound (1), approved ingress clients (2M), LB health-check paths from two public subnet CIDRs to two ports (4). Total = **15 + N + 2M**. With one API CIDR, no operator/app audience and NAT disabled, there are 49 configured resource instances. With NAT enabled, one operator, an approved bootstrap grant and one app-client CIDR, there are 57. These are configuration/mock counts; AWS-created supporting and Kubernetes-created resources are additional.

The VPC CNI and EBS CSI use dedicated web-identity roles, rather than giving their network/storage permissions to every worker Pod through the node role. These purpose-specific AWS-managed policies still contain permissions needed by the drivers; they are not a claim that every individual IAM action is resource-restricted. Workload application Pods receive no AWS role. EKS also manages a default cluster security group; inspect the actual AWS plan/console rather than claiming these supplemental rules replace AWS-managed rules.

### Network modes and application ingress

- **NAT enabled (proposed example):** worker in a private subnet, Internet downloads through one NAT gateway. One NAT across two AZs reduces resource count but creates a single-AZ egress dependency and can incur cross-AZ data charges.
- **NAT disabled (variable default):** worker in a public subnet with a billed public IPv4 address; there is no inbound SSH and no default app-client CIDR. Private subnets still exist for EKS control-plane ENIs; they have no default Internet route. Public nodes are an explicit classroom alternative, not the proposed private-node mode.
- Node egress is intentionally open for EKS bootstrap, DNS, registries and add-ons. Tight outbound controls require an explicitly designed proxy/VPC-endpoint policy; this code does not pretend a working image-pull path can use no egress.
- Install ingress-nginx with fixed service NodePorts `30080` (HTTP) and `30443` (HTTPS). Configure approved client CIDRs and set the load-balancer health check to **TCP traffic-port**, matching the SG rules. A health check to port `10256`/an allocated `healthCheckNodePort` needs a separately reviewed rule; it is not opened here. For AWS NLB instance targets, verify source-IP preservation/target health and the installed controller's current annotation requirements before use.
- A public app load balancer, controller IAM permissions, TLS certificates and DNS are separate operations. Do not label an unencrypted classroom HTTP demo as production secure. If the app should be private, prefer port forwarding and no public LB.
- The API permits only `/24`–`/32` caller CIDRs; `0.0.0.0/0` is rejected. No inbound port 22 is defined. All node internal traffic is allowed only between members of the worker SG to support VPC CNI Pods.

### Cloud bootstrap is not yet finalized

The committed application chart creates Ingress routing rules; it does not install an AWS Ingress Controller or provision a load balancer. Before claiming an AWS deployment is ready, finalize and verify the controller installation/version, chosen AWS load-balancer mode and any controller IAM role, fixed NodePorts `30080`/`30443`, TCP traffic-port health checks, allowed application audience and real target health. Metrics Server must also be installed and verified on EKS before the HPA can obtain CPU measurements. No pinned controller or Metrics Server version, LB installation or required extra IAM access is invented here. These cloud prerequisites and their approval remain pending. The separate local classroom profile already has a working Ingress Controller and Metrics Server; that local result does not verify AWS bootstrap.

## Reproducible commands

Commands below are instructions, not a report of execution. Commands marked **account action** need the approval above. Keep `terraform.tfvars`, state, binary plans, kubeconfig and raw account outputs out of Git. The root `.gitignore` must preserve these exclusions. The committed provider lockfile pins actual installed provider checksums.

### Local syntax/schema checks (no AWS account operation)

```bash
cd terraform
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
# If present, mock-provider tests do not access an AWS account:
terraform test
```

`init` contacts HashiCorp's provider registry to download the pinned AWS provider; it does not provision AWS resources. This project does not silently configure a remote state backend. Local state is sensitive. For a shared real deployment, select an approved encrypted state store with locking and narrowly scoped access before collaborators operate it; do not invent a shared bucket or credentials.

### Approve identity and produce a real plan — account actions

```bash
# Use the owner's explicitly selected sandbox role/profile, never a work profile.
# Example only: export AWS_PROFILE='OWNER_APPROVED_SANDBOX_PROFILE'
aws sts get-caller-identity
cp terraform.tfvars.example terraform.tfvars
# Edit approved account ID, actual operator CIDR, identity, resource choices and approved app audience.
terraform plan -input=false -out=tfplan
terraform show -no-color tfplan
```

Stop if the account, region, expected resource set, cluster API scope or running-cost estimate differs from approval. Retain a redacted real non-empty plan screenshot for the rubric. The mock test is not a substitute. Review existing account policies/quotas, AZ capacity, add-on compatibility and EKS standard support for the requested version. AWS selects compatible add-on defaults at creation; record the actual resolved versions after apply rather than inventing add-on version values.

### Apply and configure Kubernetes — account/network/access actions

```bash
terraform apply tfplan
aws eks update-kubeconfig \
  --region "$(terraform output -raw aws_region)" \
  --name "$(terraform output -raw cluster_name)"
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

API reachability and Kubernetes authorization are separate. If the operator lacks a tested EKS access entry/appropriate policy, stop and use the approved bootstrap procedure rather than broadening the API CIDR or changing identity. Save screenshots from the real approved region/account after redacting identifiers that should not be public. Do not publish kubeconfig or tokens.

The unapplied `k8s/storageclass-gp3.yaml` example is explicitly for **disposable classroom data**: provisioner `ebs.csi.aws.com`, `volumeBindingMode: WaitForFirstConsumer`, encryption and reclaim policy `Delete`. Use it only after the owner approves the project resources, data disposal and teardown. Helm uninstall alone retains the PostgreSQL StatefulSet PVC. Only a deliberate deletion of that project's PVC triggers CSI/PV reclamation and deletion of its backing EBS volume. Back up wanted data first. Applying this example does not retroactively change existing PV reclaim policies; do not replace an existing StorageClass or alter a live PV blindly. A volume is AZ-bound; pending Pods/PVCs need inspection, not blind scaling. One worker is not a replicated PostgreSQL setup. Do not use `emptyDir` as claimed persistent database evidence.

### Teardown after the approved demo — destructive account actions

Only the owner-approved project teardown is in scope; do not destroy existing or shared resources. Record the demo and runtime evidence first.

1. Back up any data the owner wants retained. Confirm this is the exact project/cluster/state/account.
2. After data-disposal and project-only cloud teardown approval, uninstall the app and monitoring releases and review their retained PVCs. Helm uninstall alone retains the PostgreSQL StatefulSet PVC. Deliberately delete only the approved project's disposable PVCs; with the example's `Delete` reclaim policy, the CSI driver then deletes their backing EBS volumes. Keep storage and load-balancer controllers running until PVC/PV and load-balancer finalizers finish. Remove the ingress release and any project-installed load-balancer controller only after the resources they manage have finished deleting.
3. Confirm project `LoadBalancer` Services/Ingress-owned cloud load balancers are gone, and the demo EBS PVC/PV volumes using `Delete` have been removed. Kubernetes-created resources are not tracked by this Terraform state and can outlive a VPC destroy.
4. Plan Terraform deletion, inspect the list, then apply only the approved plan:

```bash
terraform plan -destroy -input=false -out=destroy.tfplan
terraform show -no-color destroy.tfplan
terraform apply destroy.tfplan
terraform state list
```

5. Capture the **actual successful destroy output** and verify in the approved account/region that no project EKS nodes, NAT gateway/EIP, load balancer or EBS data volume remains. Do not claim teardown from an empty local state file or a failed destroy.

When cluster API teardown is needed after bootstrap privilege was revoked, arrange approved operator access **before** trying to delete Kubernetes resources. IAM/OIDC roles are deleted only as Terraform's dependency graph permits; waiting for EKS/EC2 ENIs to disappear is normal. Do not delete unrelated ENIs or modify shared VPC controls to force a teardown.

## Cost model to review before approval

Use official, current, region-specific AWS pricing—not the formulas below as a price quote. A short-lived demo's approximate pre-tax USD cost is:

```text
hours × (EKS standard-support control-plane hourly rate
       + node count × EC2 Linux On-Demand hourly rate
       + NAT gateway hourly rate, if enabled
       + allocated public IPv4 address count × IPv4 hourly rate
       + each provisioned load balancer's hourly rate)
+ NAT GB processed × regional NAT data rate
+ NLB capacity-unit hours / data processing as applicable
+ EBS gp3 GiB-month prorated by storage duration (+ charged extra IOPS/throughput)
+ CloudWatch log ingestion/storage
+ outbound/cross-AZ data transfer + any applicable taxes
```

The NAT EIP is a public IPv4 allocation. Public worker IPs add IPv4 charges only in public-node mode. A later Internet-facing load balancer can allocate additional public IPv4s in its enabled AZs. EKS compute, NAT, LB and EBS pricing are separate; AWS free-tier assumptions must not be made. EKS standard-support rates differ from extended-support rates. `support_type=STANDARD` is intentional: verify lifecycle/auto-upgrade implications and current version availability before using the template.

No fixed rate, current total price, AWS plan success, provisioned resource or teardown success is asserted in this file. Approved start time, resource IDs, actual charges/estimates, evidence and stop time belong in the root evidence log after they are observed.
