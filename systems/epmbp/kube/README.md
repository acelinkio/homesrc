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
# apply manifests
kubectl apply -f manifests/
# bring your own cert, not adding secretsmanager/certmanager
kubectl create secret tls wildcarddev --cert=tls.crt --key=tls.key -n certifcate
```

```sh
# delete colima vm
colima delete --data -p localdev
```