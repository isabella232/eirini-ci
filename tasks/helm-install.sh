#!/bin/bash

set -ex

readonly DIRECTOR_DIR="state/environments/softlayer/director/$DIRECTOR_NAME"
readonly CF_DEPLOYMENT="$DIRECTOR_DIR/cf-deployment/vars.yml"
readonly TMP_CERTS_PATH="certs/"
readonly CERT_PATH="${TMP_CERTS_PATH}/cc_cert"
readonly CA_PATH="${TMP_CERTS_PATH}/cc_ca"
readonly PRIVATE_KEY_PATH="${TMP_CERTS_PATH}/cc_priv"
export BOSH_CLIENT=admin
BOSH_CLIENT_SECRET=$(bosh interpolate "$DIRECTOR_PATH/vars.yml" --path /admin_password)
export BOSH_CLIENT_SECRET
readonly HELM_DIR=eirini-helm-release/kube-release/helm/eirini

./ci-resources/scripts/setup-env.sh
./ci-resources/scripts/bosh-login.sh

main(){
  create_and_set_namespace
  create_cc_certs_secret
  copy_helm_config_files
  helm_install_or_upgrade
}

create_and_set_namespace(){
  set +e
  if kubectl get namespace "$KUBE_NAMESPACE"; then
    echo "namespace $KUBE_NAMESPACE exits"
  else
    kubectl create namespace "$KUBE_NAMESPACE"
    echo "namespace $KUBE_NAMESPACE created"
  fi
  kubectl config set-context "$(kubectl config current-context)" --namespace="$KUBE_NAMESPACE"
  set -e
}

create_cc_certs_secret() {
  get_certs_from_vars
  create_kube_secret
}

get_certs_from_vars() {
  mkdir -p "$TMP_CERTS_PATH"
  bosh int "${CF_DEPLOYMENT}/vars.yml" --path /cc_bridge_cc_uploader/certificate >"${TMP_CERTS_PATH}/cc_cert"
  bosh int "${CF_DEPLOYMENT}/vars.yml" --path /cc_bridge_cc_uploader/private_key >"${TMP_CERTS_PATH}/cc_priv"
  bosh int "${CF_DEPLOYMENT}/vars.yml" --path /cc_bridge_cc_uploader/ca >"${TMP_CERTS_PATH}/cc_ca"
}

remove_tmp_certs_path() {
  [ -d $TMP_CERTS_PATH ] && rm -r $TMP_CERTS_PATH
}

copy_helm_config_files(){
  cp configs/opi.yaml $HELM_DIR/configs/
  kubectl config view --flatten > $HELM_DIR/configs/kube.yaml
}

helm_install_or_upgrade(){
  if helm history "$TAG"; then
    helm upgrade \
      "$TAG" \
      eirini-helm-release/kube-release/helm/eirini \
      --set-string "ingress.opi.host=opi-$DIRECTOR_NAME.$KUBE_ENDPOINT" \
      --set-string "config.opi_image=eirini/opi:$TAG" \
      --set-string "config.registry_image=eirini/registry:$TAG" \
      --set-string "ingress.registry.host=registry-$DIRECTOR_NAME.$KUBE_ENDPOINT"
  else
    helm install \
      eirini-helm-release/kube-release/helm/eirini \
      --namespace "$KUBE_NAMESPACE" \
      --set-string "ingress.opi.host=opi-$DIRECTOR_NAME.$KUBE_ENDPOINT" \
      --set-string "ingress.registry.host=registry-$DIRECTOR_NAME.$KUBE_ENDPOINT" \
      --set-string "config.registry_image=eirini/registry:$TAG" \
      --set-string "config.opi_image=eirini/opi:$TAG" \
      --debug \
      --name "$TAG"
  fi
}

trap remove_tmp_certs_path EXIT
main
