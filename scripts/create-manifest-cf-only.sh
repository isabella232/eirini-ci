#!/bin/bash

bosh interpolate cf-deployment/cf-deployment.yml \
    --vars-store "$DIRECTOR_PATH/cf-deployment/vars.yml" \
    --ops-file cf-deployment/operations/experimental/enable-bpm.yml \
    --ops-file cf-deployment/operations/use-compiled-releases.yml \
    --ops-file cf-deployment/operations/bosh-lite.yml \
    --ops-file cf-deployment/operations/experimental/use-bosh-dns.yml \
    --ops-file eirini-release/operations/capi-dev-version.yml \
    --ops-file eirini-release/operations/enable-opi.yml \
    --ops-file cf-deployment/iaas-support/softlayer/add-system-domain-dns-alias.yml \
    --var system_domain="$DIRECTOR_IP.nip.io" \
    --var opi_cf_url="registry-$DIRECTOR_NAME.$KUBE_NAMESPACE:80" \
  > manifest/manifest.yml