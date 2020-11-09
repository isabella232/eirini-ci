#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"
export KUBECONFIG="$PWD/kube/config"

ensure-istio-ns() {
  kubectl create namespace istio-system || true
}

deploy-cf() {
  kapp deploy -a cf -f <(
    ytt -f "patched-cf-for-k8s/config" \
      -f ci-resources/cf-for-k8s \
      -f cluster-state/environments/kube-clusters/"${1}"/default-values.yml \
      -f cluster-state/environments/kube-clusters/"${1}"/loadbalancer-values.yml
  ) -y
}

# we've removed istio-system namespace from cf-for-k8s yaml so that letsencrypt
# certificate survives redeploys
ensure-istio-ns

deploy-cf "$CLUSTER_NAME"
