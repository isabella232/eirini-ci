#!/bin/bash

set -eu

export KUBECONFIG="$PWD/kube/config"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"

helm init --client-only
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install postfacto-redis bitnami/redis \
  --namespace postfacto-redis \
  --set securityContext.fsGroup=65531
