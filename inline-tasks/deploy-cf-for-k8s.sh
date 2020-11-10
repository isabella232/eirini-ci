#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"
export KUBECONFIG="$PWD/kube/config"

generate-cert-values() {
  local values_file tls_key tls_crt
  values_file="$1"
  tls_key="$(kubectl get secret -n cert-manager eirinidotcf-cert -o jsonpath="{.data['tls\.key']}")"
  tls_crt="$(kubectl get secret -n cert-manager eirinidotcf-cert -o jsonpath="{.data['tls\.crt']}")"

  cat "$values_file" <<EOF
#@data/values
---
workloads_certificate:
   crt: |
     $tls_crt
   key: |
     $tls_key
   ca: ""
EOF
}

deploy-cf() {
  if [[ "$USE_CERT_MANAGER" == "true" ]]; then
    cert_values="$(mktemp)"
    generate_cert_values "$cert_values"
    extra_args=(
      "-f ci-resources/cert-manager"
      "-f $cert_values"
    )
  fi

  kapp deploy -a cf -f <(
    ytt -f "patched-cf-for-k8s/config" \
      -f ci-resources/cf-for-k8s \
      -f cluster-state/environments/kube-clusters/"${1}"/default-values.yml \
      -f cluster-state/environments/kube-clusters/"${1}"/loadbalancer-values.yml \
      ${extra_args[@]}
  ) -y
}

deploy-cf "$CLUSTER_NAME"
