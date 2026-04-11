# extract secrets from other cluster
```sh
# certs
kubectl create namespace certificate
kubectl --context tp2 get secret wildcarddotdev-production -n certificate -o jsonpath='{.data.tls\.crt}' | base64 -d > tls.crt
kubectl --context tp2 get secret wildcarddotdev-production -n certificate -o jsonpath='{.data.tls\.key}' | base64 -d > tls.key
# grafana admin credentials
kubectl create namespace observability
kubectl --context tp2 get secret grafana-admin-credentials -n observability -o jsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d > grafana_password.secret
kubectl --context tp2 get secret grafana-admin-credentials -n observability -o jsonpath='{.data.GF_SECURITY_ADMIN_USER}' | base64 -d > grafana_admin.secret
```

# finsihing kube setup
```sh
kubectl create namespace cilium-system
kubectl create namespace clickhouse-operator
kubectl create namespace grafana-operator
kubectl create namespace opentelemetry-operator
kubectl create namespace local-path-storage
kubectl create namespace envoy-gateway
# apply helm charts
helmfile template --include-crds | kubectl apply -f -
# hacks
## bring your own cert, not adding secretsmanager/certmanager
kubectl create namespace certificate
kubectl create secret tls wildcarddev --cert=tls.crt --key=tls.key -n certificate
kubectl create secret generic clickhouse-passwords --from-literal=collector=$(uuidgen) --from-literal=grafana=$(uuidgen) -n observability
## bring grafana admin credentials
kubectl create secret generic grafana-admin-credentials --from-file=GF_SECURITY_ADMIN_USER=grafana_admin.secret --from-file=GF_SECURITY_ADMIN_PASSWORD=grafana_password.secret -n observability

# apply manifests
kubectl apply -f manifests/
```

```sh
# delete colima vm
colima delete --data -p localdev
```