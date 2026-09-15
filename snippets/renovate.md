# grab new versions in text
```sh
LOG_LEVEL=debug LOG_FORMAT=json renovate --platform=local 2>/dev/null \
  | jq -r 'select(.msg=="packageFiles with updates").config.helmfile[].deps[]
           | select(.updates|length>0)
           | "\(.depName): \(.currentVersion) -> \(.updates[].newVersion) (\(.updates[].updateType))"'
```