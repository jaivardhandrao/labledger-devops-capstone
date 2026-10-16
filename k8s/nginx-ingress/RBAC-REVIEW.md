# New-cluster bootstrap grants — review only

No grants have been applied. These are Kubernetes permissions for the proposed **new personal EKS cluster only**. They do not authorize changing any local, school/work or pre-existing cloud cluster. The root action review separately covers the EKS access entry/administrator policy association needed by the bootstrap caller.

## F5/NGINX controller

Offline rendering produces 11 objects: two ConfigMaps, one Deployment, one NodePort Service, one IngressClass, one Lease, and five RBAC/identity objects. The latter are ServiceAccount `nginx-ingress`, Role/RoleBinding `nginx-ingress` in namespace `nginx-ingress`, plus ClusterRole/ClusterRoleBinding `nginx-ingress`.

The **actual upstream ClusterRole** permits:

- Cluster-wide get/list/watch of ConfigMaps, namespaces, Pods and **Secrets**.
- Cluster-wide Service get/list/watch/create/update/patch/delete.
- EndpointSlice and Ingress get/list/watch, node list, workload get and IngressClass get/list.
- Event create/patch/list, lease list/watch and Ingress status update.

The namespaced Role additionally permits controller ConfigMap/Pod/Secret/Service reads, Pod update, Events and leader-election lease operations. `watchNamespace`/`watchSecretNamespace` restrict controller behavior to `labledger`; **they do not narrow the ClusterRole's authorization**. Review this broader Secret-read and Service-management capability explicitly before installation. Exact rendered rules, subjects and bindings are in `rendered-rbac-review.yaml`.

No vendor CRDs, NGINX Plus license, AWS IAM role, IRSA annotation or AWS Load Balancer Controller is requested. The controller needs its Kubernetes ServiceAccount token to watch the API. It remains separate from the application's token-free Pods.

## Prometheus/Grafana operator stack

Offline inventory for the existing pinned `kube-prometheus-stack` 92.9.0 with project values contains:

- 10 Prometheus Operator CRDs, including Prometheus, ServiceMonitor, PodMonitor, PrometheusRule, Alertmanager, Probe, ScrapeConfig and related resources; installing a CRD extends the whole cluster's API.
- 5 ClusterRoles and 5 ClusterRoleBindings: `monitoring-grafana-clusterrole`, `monitoring-kube-state-metrics`, `monitoring-operator`, `monitoring-prometheus` and `monitoring-admission` (binding names are recorded exactly in the JSON inventory).
- One namespaced admission Role/RoleBinding, seven rendered ServiceAccounts, and one mutating plus one validating admission webhook configuration. The seventh Grafana test ServiceAccount is test-hook-only, not a claim of seven permanently running accounts. Admission-hook resources can be transient, but their creation/permissions still require approval.

Secret-related capabilities are broader than dashboard selectors: Grafana's ClusterRole has global ConfigMap/Secret get/list/watch; kube-state-metrics can list/watch Secrets; the operator can get/list/watch/create/update/delete ConfigMaps/Secrets. Prometheus receives cluster discovery/scraping permissions. The admission role can get/create Secrets in `monitoring`; its ClusterRole can get/update/patch the monitoring webhook configurations. Webhooks apply to create/update of monitoring `PrometheusRule` and, for validation, `AlertmanagerConfig` resources.

ServiceAccounts: `monitoring-grafana`, `monitoring-kube-state-metrics`, `monitoring-prometheus-node-exporter`, `monitoring-operator`, `monitoring-prometheus`, `monitoring-grafana-test` (test hook), `monitoring-admission` (admission hook). Full names, namespaces, rules, role references and subjects are in `monitoring-bootstrap-grants-review.json`.

Official monitoring chart repository: https://prometheus-community.github.io/helm-charts ; pinned package 92.9.0 SHA256 `d99bc9dca70d8a2844e59ca18e589bfd69014b5c46d0be05ba8587932048b07f`.

This inventory is preparation, not permission to install. Bootstrap approval must cover these cluster-wide CRDs, RBAC, webhooks, both new namespaces and the externally generated application/Grafana Secrets on the new personal cluster only. No credentials or Secret values appear in the review artifacts. The existing local cluster remains unchanged.
