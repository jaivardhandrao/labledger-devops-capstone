# Prepared AWS Ingress bootstrap — not installed

This uses the F5/NGINX **OSS** Ingress Controller from its official Helm repository, rather than the separate community ingress-nginx project. Package inspection verified chart **2.8.0**, controller **5.7.0**, and Kubernetes requirement `>=1.25.0-0`; the planned EKS version is 1.34. The actual downloaded package SHA256 is pinned in `chart.lock.json`.

- Official repository: https://helm.nginx.com/stable
- Source recorded in the package: https://github.com/nginx/kubernetes-ingress/tree/v5.7.0/charts/nginx-ingress
- Controller package SHA256: `a48a61321273160cd4f58ff4c4de9aed169097e1203de1f2ca1579c0236c6703`
- Local downloaded package: `/tmp/labledger-capstone-tools/nginx-ingress-2.8.0.tgz` (not committed).

`values.yaml` prepares two replicas with requests/limits, `/nginx-ready` readiness/startup probes, non-root vendor security defaults and a read-only root. It watches only `labledger`, uses class `nginx`, and keeps strict host validation. Plus, vendor custom resources, snippets, telemetry, external DNS, cert-manager integration and controller monitoring extensions are disabled.

The Service is **NodePort**, never `LoadBalancer`: HTTP 80→30080 and HTTPS 443→30443. Terraform separately owns the public NLB, its TCP 80 listener, target group and ASG attachment. The approved plan currently has **no 443 listener or TLS certificate**; 30443 is a prepared Service port and does not establish working public HTTPS. `externalTrafficPolicy: Cluster` lets any registered worker forward to a Ready controller Pod. No AWS Load Balancer Controller, extra IAM role or IRSA annotation is introduced.

The application Ingress must use the exact Terraform NLB DNS hostname:

```bash
NLB_DNS=$(terraform -chdir=terraform output -raw application_nlb_dns_name)
# On the approved SHA-tagged application deployment, supply:
# --set-string ingress.host="$NLB_DNS" --set ingress.className=nginx
```

Run that output command only after an approved apply. It needs no purchased custom domain. The helper also supplies this hostname as NGINX's documented `external-status-address` configuration so it does not wait for a nonexistent LoadBalancer Service address. It does not permit hostless/catch-all Ingress.

## Local review and validation

```bash
helm repo add nginx-stable https://helm.nginx.com/stable
helm pull nginx-stable/nginx-ingress --version 2.8.0 --destination /tmp/labledger-capstone-tools
NGINX_CHART=/tmp/labledger-capstone-tools/nginx-ingress-2.8.0.tgz \
  ./scripts/cluster-bootstrap-ingress.sh --render
```

The package is checked against the recorded SHA before rendering. Local Helm lint/render and semantic checks passed against Kubernetes 1.34. The example hostname in render fixtures is explicitly a test fixture, not a deployed endpoint. No AWS API or kubeconfig is read in render mode.

## Separate reviewed installation

Do not run install mode until the exact new-cluster bootstrap grant review is approved. It creates Kubernetes RBAC and cluster objects; values files alone are not an approval. `rendered-rbac-review.yaml` and `RBAC-REVIEW.md` show the actual grants.

The installer requires `BOOTSTRAP_GRANTS_APPROVED=yes`, the reviewed personal `AWS_ACCOUNT_ID`, exact EKS ARN in `EXPECTED_EKS_CONTEXT`, matching new-cluster name in `APPROVED_EKS_CLUSTER_NAME`, a dedicated existing `CLOUD_KUBECONFIG` outside Git, `NLB_DNS` from the actual Terraform output, and the pinned local `NGINX_CHART`. It rejects local/work aliases and an ARN outside the supplied personal account/ap-south-1 context. The outer approved workflow injects personal credentials into subprocess environment only; this helper never reads the key file or edits AWS profiles/global kubeconfig.

`--install-reviewed` applies the application namespace and installs release `nginx-ingress` into namespace `nginx-ingress` using explicit kubeconfig/context flags and `--skip-crds`. It creates no AWS load balancer or IAM access mapping. It checks deployment rollout and Service configuration; these commands have not been run against AWS.

Metrics Server is handled separately by Terraform's reviewed managed addon `v0.9.0-eksbuild.13`, with its 10251 control-plane/node rules. This controller helper does not install a second Metrics Server.
# Reproducible schema resolution

Chart 2.8.0 references an upstream Kubernetes JSON schema during values validation.
If that external request times out, download the exact `source_url` in
[schema.lock.json](schema.lock.json) to a local file and set
`NGINX_SCHEMA_DEFINITIONS=/absolute/path/to/_definitions.json` before running the
bootstrap helper. The helper verifies both file checksums, resolves only the 82
known references locally, and checks that every other chart file is unchanged.
Helm schema validation remains enabled. The prepared chart is temporary and
contains no credentials or cluster state.

The controller uses its readiness probe on 8081. Its optional chart startup probe
is disabled because enabling it on the same port produces duplicate container port
keys that Kubernetes server-side apply rejects. Application startup/readiness
probes remain enabled independently.
