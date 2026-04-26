To create crds.yaml need to template cert-manager templates/crds.yaml with the desired version

```
helm template jetstack/cert-manager --version v1.20.2 --set crds.enabled=true -s templates/crd-acme.cert-manager.io_challenges.yaml -s templates/crd-acme.cert-manager.io_orders.yaml -s templates/crd-cert-manager.io_certificaterequests.yaml -s templates/crd-cert-manager.io_certificates.yaml -s templates/crd-cert-manager.io_clusterissuers.yaml -s templates/crd-cert-manager.io_issuers.yaml > crds/crds.yaml
```