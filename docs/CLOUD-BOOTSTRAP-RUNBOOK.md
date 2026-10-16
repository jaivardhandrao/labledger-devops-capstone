# Reviewed EKS bootstrap and evidence runbook

**Executed reference:** the [actual run and verified cleanup](../evidence/aws-live-2026-10-16/README.md) supersede the original preparation status. The commands below remain a reproduction runbook, not authorization to incur new charges. The temporary environment is retired.

## Source packages and prerequisites

| Item | Verified preparation |
|---|---|
| Controller | F5/NGINX OSS chart 2.8.0/controller 5.7.0; `/tmp/labledger-capstone-tools/nginx-ingress-2.8.0.tgz`; SHA256 in `k8s/nginx-ingress/chart.lock.json` |
| Monitoring | kube-prometheus-stack 92.9.0/operator v0.94.1; `/tmp/labledger-capstone-tools/kube-prometheus-stack-92.9.0.tgz`; SHA256 in `monitoring/chart.lock.json` |
| EKS | Reviewed Kubernetes 1.34, explicit personal account and new-cluster ARN, dedicated kubeconfig outside Git |
| Worker/add-ons | Ready worker; VPC CNI/CoreDNS/kube-proxy/EBS CSI; reviewed managed Metrics Server `v0.9.0-eksbuild.13` and control-plane/node 10251 rules |
| Images | Exact successful main-push commit SHA; both GHCR SHA tags must actually be pullable by this new cluster under the approved package-visibility/access decision |
| Access | Temporary approved new-cluster bootstrap privileges for namespaces, RBAC, IngressClass, operator CRDs/webhooks and cleanup; namespace edit alone is insufficient |

Keep personal credentials in the approved outer subprocess environment, outside Git/logs/screenshots. Do not source arbitrary credential-file contents as shell code, modify AWS work profiles, or reuse a local/work kubeconfig. Every kubectl/Helm invocation must provide the dedicated file and exact context. No GitHub Actions AWS OIDC grant is included; do not enable automatic cloud deployment or add long-lived AWS keys to GitHub as a shortcut.

## Bootstrap sequence after exact approval

1. Apply only the exact reviewed plan using the verified personal identity. Record actual start time and reserve cleanup time inside the lifetime. Capture genuine infrastructure/plan evidence.
2. Read local Terraform outputs `cluster_name`, `aws_region`, `application_nlb_dns_name` and `application_nlb_target_group_arn`. Generate the dedicated project kubeconfig with the approved identity; do not change the global current context. Set `AWS_ACCOUNT_ID`, `APPROVED_EKS_CLUSTER_NAME`, `EXPECTED_EKS_CONTEXT` (exact ARN), `CLOUD_KUBECONFIG` and `NLB_DNS` to those reviewed/actual values.
3. Verify the worker is Ready, EBS CSI controller/node components and `ebs.csi.aws.com` driver are available, and the managed Metrics Server works. Its 10251 listener is separate from the kubelet 10250 scraping path. Do not install another Metrics Server. Verify the actual `metrics.k8s.io` API/`kubectl top` before claiming CPU HPA works.
4. After explicit resource/data-disposal approval, apply `k8s/storageclass-gp3.yaml`: encrypted gp3, `WaitForFirstConsumer`, **Delete** reclamation. Then use `database.storage.className=gp3`. Volume binding waits for the database Pod's placement; inspect the actual PVC/PV and AZ. Existing PVs do not inherit later StorageClass policy edits.
5. Create the application/monitoring namespaces and strong generated database/Grafana Secrets only through the approved private input/in-process workflow. Keep values out of chart files, command arguments and logs. `labledger-db` needs `username`, `password`, `database`, `database-url`; `monitoring-grafana-admin` needs `username`, `password`. A password change in a Secret does not rotate credentials inside an initialized database.
6. Run the reviewed controller helper with the pinned local package, approved-grants flag, exact context and actual NLB DNS. It creates the standard Ingress controller only: NodePort 30080/30443, two replicas, class `nginx`, watch scope `labledger`. Its actual upstream ClusterRole scope remains broader; see the grant review. It creates no AWS LB/IAM role/IRSA or vendor CRDs.
7. Run `scripts/cluster-bootstrap-monitoring.sh --install-reviewed` with the same exact dedicated context and pinned `PROMETHEUS_CHART`. This installs the reviewed operator CRDs/RBAC/webhooks, base monitoring values plus `values-eks.yaml`, and the dashboard ConfigMap. The external Grafana Secret must already exist. UIs stay ClusterIP.
8. Deploy application chart inputs from the reviewed SHA archive, matching both actual GHCR SHA tags. Require `frontend.replicaCount=2`, `backend.replicaCount=2`, `backend.autoscaling.minReplicas=2`, `database.storage.className=gp3`, `monitoring.enabled=true`, `ingress.className=nginx` and **`ingress.host=$NLB_DNS`**. Keep the external DB Secret reference. Do not substitute local image tags or a hostname placeholder.

Useful output commands, only after approved apply:

```bash
terraform -chdir=terraform output -raw cluster_name
terraform -chdir=terraform output -raw application_nlb_dns_name
terraform -chdir=terraform output -raw application_nlb_target_group_arn
```

The NLB owns TCP 80→instance NodePort 30080 with TCP health checks. No cloud LoadBalancer Service/controller, custom domain or 443 listener is part of this plan. The prepared 30443 Service port does not make public HTTPS work. Use the actual NLB hostname in both the app's strict Ingress host rule and the controller's external-status address. Verify NLB targets and both `/` and `/api/loans` before calling the application public/healthy.

## Verify real cloud behavior

Capture actual PostgreSQL migration/table, DB-dependent readiness, two Ready frontend/two Ready backend Pods, ClusterIP Services, successful Helm releases, image identities, bound gp3 PVC and real Ingress CRUD. HPA may increase API Pods to four; no worker autoscaler exists. Record requests, CPU, desired/current replicas and actual Ready Pods. Any load must be bounded and use persistent connections; no synthetic success screenshots or invented counts.

`monitoring/values-eks.yaml` disables only the chart's direct self-hosted etcd/controller-manager/scheduler Pod/node endpoint discovery, which does not apply to the managed control-plane topology. It preserves API-server, kubelet/cAdvisor/probe, CoreDNS, kube-proxy, node exporter, kube-state-metrics, operator, Prometheus, Grafana and application discovery. This is not a claim that all provider-supported EKS control-plane observability is unavailable. The official EKS control-plane metrics page is a verification/reference destination; this preparation did not browse it or test live EKS endpoints.

Inspect **all** actual active targets after deployment. Do not assume the local count 14 applies to EKS or hide failed application/node targets. Diagnose any remaining failure against actual bindings, TLS/RBAC, selectors and network rules; permission/network changes require the corresponding review. Populate dashboard panels with actual application requests. Grafana's browser login remains the user's step unless a permitted authenticated School-profile session exists. Keep real cloud and historical local evidence distinct.

## Teardown while drivers and access still exist

1. Preserve real cloud/demo/update evidence and any owner-requested backup first. Confirm exact account, cluster, Terraform state and approved disposable project data.
2. Record the PostgreSQL PVC's bound PV, actual `persistentVolumeReclaimPolicy`, CSI driver and EBS volume handle before removing the application. Current source is **Delete**; inspect the live PV because it may differ. If it is Retain, stop for the specifically reviewed retained-volume cleanup decision instead of silently changing a live policy or deleting another volume.
3. Uninstall the project application so its Pods release the volume. Helm retains the StatefulSet PVC; after approved data disposal, delete only that project's exact PVC. Keep EBS CSI, worker, CSI IAM role and temporary approved bootstrap access alive while finalizers/detach/delete complete.
4. Verify the PV is removed and the exact EBS volume is gone using authorized read-only checks. A deleted PVC or successful Helm uninstall alone is insufficient proof. Do not remove CSI/node/IAM first; that can strand the volume/finalizer and prolong charges.
5. Remove only the reviewed project monitoring/controller workloads. Then run the exact reviewed Terraform teardown to remove its NLB/listener/target attachment, add-ons, node group, cluster, networking/IAM and temporary access association. Do not create another grant for cleanup. Operator CRDs are cluster-scoped and may outlive Helm uninstall until the dedicated cluster is deleted.
6. Verify actual project resources, EBS/NLB/EIP/ENIs and cloud stack deletion; record genuine destroy completion evidence. Do not delete unrelated/shared resources. Do not claim a hard spending cutoff from documentation or an alert.
