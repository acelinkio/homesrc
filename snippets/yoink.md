# flux yoink

# helm repo
```sh
curl -sL "https://github.com/joryirving/home-ops/raw/refs/heads/main/kubernetes/apps/base/llm/openclaw/app/helmrelease.yaml" | yq eval-all 'explode(.) | select(.kind == "HelmRelease")' - | yq eval '.spec.values' > miniflux-values.yaml
helm template miniflux --repo https://bjw-s.github.io/helm-charts app-template -f miniflux-values.yaml | yq > miniflux.yaml
```

# oci
```sh
APP=openclaw
OCI=oci://ghcr.io/bjw-s-labs/helm/app-template
VER=4.6.2
SRC="https://github.com/joryirving/home-ops/raw/refs/heads/main/kubernetes/apps/base/llm/openclaw/app/helmrelease.yaml"

echo "APP=$APP"
echo "OCI=$OCI"
echo "VER=$VER"
echo "SRC=$SRC"
curl -sL "$SRC" | yq eval-all 'explode(.) | select(.kind == "HelmRelease")' - | yq eval '.spec.values' > $APP-values.yaml
helm template $APP $OCI -f $APP-values.yaml | yq > $APP.yaml
```