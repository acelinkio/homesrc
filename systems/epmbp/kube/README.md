# secerts
this cluster will not be hooked up to an external secrets provider.
any secrets created by hand will be put into clusterstore namespace
then shared via external-secrets--to stay inline with ideal approach

if moving into another cluster, just swap out the clustoresecretstore!

# extract secrets from other cluster
```sh
# certs
kubectl --context tp2 get secret wildcarddotdev-production -n certificate -o jsonpath='{.data.tls\.crt}' | base64 -d > tls.crt
kubectl --context tp2 get secret wildcarddotdev-production -n certificate -o jsonpath='{.data.tls\.key}' | base64 -d > tls.key
# grafana admin credentials
kubectl --context tp2 get secret grafana-admin-credentials -n observability -o jsonpath='{.data.GF_SECURITY_ADMIN_PASSWORD}' | base64 -d > grafana_password.secret
kubectl --context tp2 get secret grafana-admin-credentials -n observability -o jsonpath='{.data.GF_SECURITY_ADMIN_USER}' | base64 -d > grafana_admin.secret
```

# importing these imperative secrets
```sh
kubectl create namespace secretstore
kubectl create secret tls wildcarddev --cert=tls.crt --key=tls.key -n secretstore
# may consider adding external-secrets generator instead
kubectl create secret generic clickhouse-passwords --from-literal=collector=$(uuidgen) --from-literal=grafana=$(uuidgen) -n secretstore
kubectl create secret generic grafana-admin-credentials --from-file=GF_SECURITY_ADMIN_USER=grafana_admin.secret --from-file=GF_SECURITY_ADMIN_PASSWORD=grafana_password.secret -n secretstore
```

# finsihing kube setup
```sh
# create the namespaces in helmfile beforehand
# note this requires the golang version of yq
helmfile template | \
  yq ea '.metadata.namespace // ""' - | sort -u | grep -v '^---' | grep -v '^$' | \
  while read ns; do
    echo "---"
    echo "apiVersion: v1"
    echo "kind: Namespace"
    echo "metadata:"
    echo "  name: $ns"
  done | kubectl apply -f -

# apply helm charts
helmfile template --include-crds | kubectl apply -f -
# apply manifests
kubectl apply -f manifests/
```

```sh
# delete colima vm
colima delete --data -p localdev
```