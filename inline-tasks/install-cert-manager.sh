#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"
export KUBECONFIG="$PWD/kube/config"

install-cert-manager() {
  if ! kubectl get namespace cert-manager; then
    kubectl create namespace cert-manager
  fi

  helm init
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm upgrade \
    --install \
    cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.0.4 \
    --set installCRDs=true
}

install-cert-manager
