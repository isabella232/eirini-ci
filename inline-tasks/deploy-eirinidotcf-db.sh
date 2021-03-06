#!/bin/bash

set -euo pipefail

export KUBECONFIG
KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}
KUBECONFIG=$(readlink -f "$KUBECONFIG")

export GOOGLE_APPLICATION_CREDENTIALS
GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS:-""}
if [[ -n $GOOGLE_APPLICATION_CREDENTIALS ]]; then
  GOOGLE_APPLICATION_CREDENTIALS=$(readlink -f "$GOOGLE_APPLICATION_CREDENTIALS")
fi

confdir=$PWD/db-conf
cd eirinidotcf/db
./helm-install-db.sh

kubectl get secret --namespace pheed-db pheed-mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode >"$confdir/mysql-root-password"
kubectl get service -npheed-db pheed-mysql -ojsonpath='{.spec.ports[?(.name=="mysql")].nodePort}' >"$confdir/mysql-port"
kubectl get nodes -o wide --no-headers | awk '{ print $7 }' | head -1 >"$confdir/mysql-ip-address"
