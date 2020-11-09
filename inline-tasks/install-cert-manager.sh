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

ensure-istio-ns() {
  if ! kubectl get namespace istio-system; then
    kubectl create namespace istio-system
  fi
}

configure-certs() {
  if ! kubectl get secret -n istio-system clouddns-dns01-solver-svc-acct; then
    key_file=$(mktemp)
    trap "rm $key_file" RETURN
    echo "$DNS_SERVICE_ACCOUNT_JSON" >"$key_file"
    kubectl create secret -n istio-system generic clouddns-dns01-solver-svc-acct --from-file="$key_file"
  fi

  cert_config_file=$(mktemp)
  cat <<EOF >>"$cert_config_file"
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
  namespace: istio-system
spec:
  acme:
    email: eirini@cloudfoundry.org
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging-private-key
    solvers:
      - dns01:
          cloudDNS:
            # The ID of the GCP project
            project: "$GCP_PROJECT_ID"
            # This is the secret used to access the service account
            serviceAccountSecretRef:
              name: clouddns-dns01-solver-svc-acct
              key: key.json

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: eirinidotcf-cert
  namespace: istio-system
spec:
  secretName: eirinidotcf-cert
  commonName: eirini.cf
  dnsNames:
  - eirini.cf
  - '*.apps.cf4k8s4a8e.ci-envs.eirini.cf-app.com'
  issuerRef:
    name: letsencrypt-staging
EOF

  kubectl apply -f "$cert_config_file"
  rm "$cert_config_file"
}

install-cert-manager

# we've removed istio-system namespace from cf-for-k8s yaml so that letsencrypt
# certificate survives redeploys
ensure-istio-ns

configure-certs
