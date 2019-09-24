#!/bin/bash

set -xeuo pipefail
IFS=$'\n\t'

readonly CLUSTER_DIR="environments/kube-clusters/$CLUSTER_NAME"
readonly BITS_SECRET="bits"
readonly ENABLE_STAGING=${ENABLE_OPI_STAGING:-true}
readonly STORAGE_CLASS=${STORAGE_CLASS:-hostpath}

main() {
  set-kube-state
  copy-output
}

set-kube-state() {
  local cluster_domain
  cluster_domain="${CLUSTER_NAME}.ci-envs.eirini.cf-app.com"

  pushd cluster-state
  mkdir --parent "$CLUSTER_DIR"
  cat >"$CLUSTER_DIR"/scf-config-values.yaml <<EOF
bits:
  env:
    DOMAIN: $cluster_domain
  kube:
    external_ips: []
  opi:
    ingress_endpoint: $cluster_domain
    use_registry_ingress: true
  secrets:
    BITS_SERVICE_SECRET: $BITS_SECRET
    BITS_SERVICE_SIGNING_USER_PASSWORD: $BITS_SECRET
    BLOBSTORE_PASSWORD: $BITS_SECRET
  tls_secret_name: ingress-tls

env:
    DOMAIN: $cluster_domain

    UAA_HOST: uaa.$cluster_domain
    UAA_PORT: 443
    ENABLE_OPI_STAGING: $ENABLE_STAGING

kube:
    storage_class:
      persistent: "$STORAGE_CLASS"
      shared: "$STORAGE_CLASS"
    auth: rbac

secrets:
    CLUSTER_ADMIN_PASSWORD: $CLUSTER_ADMIN_PASSWORD
    UAA_ADMIN_CLIENT_SECRET: $UAA_ADMIN_CLIENT_SECRET
    BLOBSTORE_PASSWORD: $BITS_SECRET

ingress:
  enabled: true
  annotations:
    "nginx.ingress.kubernetes.io/proxy-body-size": "100m"

sizing:
  diego_cell:
    count: $DIEGO_CELL_COUNT

eirini:
  opi:
    use_registry_ingress: true
    ingress_endpoint: $cluster_domain

  secrets:
    BLOBSTORE_PASSWORD: $BITS_SECRET

EOF
  popd
}

copy-output() {
  pushd cluster-state || exit
  if git status --porcelain | grep .; then
    echo "Repo is dirty"
    git add "$CLUSTER_DIR/scf-config-values.yaml"
    git config --global user.email "eirini@cloudfoundry.org"
    git config --global user.name "Come-On Eirini"
    git commit --all --message "update/add scf values file"
  else
    echo "Repo is clean"
  fi
  popd || exit

  cp -r cluster-state/. state-modified/
}

main