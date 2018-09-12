#!/bin/bash

opsfiles=(
    "--ops-file" "cf-deployment/operations/experimental/enable-bpm.yml"
    "--ops-file" "cf-deployment/operations/use-compiled-releases.yml"
    "--ops-file" "cf-deployment/operations/bosh-lite.yml"
    "--ops-file" "eirini-release/operations/capi-dev-version.yml"
    "--ops-file" "eirini-release/operations/enable-opi.yml"
    "--ops-file" "eirini-release/operations/disable-router-tls.yml"
    "--ops-file" "1-click/operations/add-system-domain-dns-alias.yml"
    "--ops-file" "eirini-release/operations/opi.yml"
    "--ops-file" "eirini-release/operations/dev-version.yml"
    "--ops-file" "eirini-release/operations/bosh-lite-static-ip.yml"
)

if [ "$ENABLE_OPI_STAGING" = true ]; then
  opsfiles+=("--ops-file" "eirini-release/operations/enable-opi-staging.yml")
fi

bosh interpolate cf-deployment/cf-deployment.yml \
    --vars-store "$DIRECTOR_PATH/cf-deployment/vars.yml" \
    --var=k8s_flatten_cluster_config="$(kubectl config view --flatten=true)" \
    "${opsfiles[@]}" \
    --var system_domain="$DIRECTOR_IP.nip.io" \
    --var cc_api="https://api.$DIRECTOR_IP.nip.io" \
    --var cc_uploader_ip="$DIRECTOR_IP" \
    --var kube_namespace="$KUBE_NAMESPACE" \
    --var kube_endpoint="$KUBE_ENDPOINT" \
    --var nats_ip="$NATS_IP" \
    --var registry_address="registry.$DIRECTOR_IP.nip.io:$REGISTRY_PORT" \
    --var opi_cf_url="http://opi.service.cf.internal:8085" \
    --var eirini_local_path=eirini-release \
    --var static_ip="$EIRINI_IP" \
  > manifest/manifest.yml
