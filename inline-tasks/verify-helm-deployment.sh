#!/bin/bash

set -euo pipefail

export KUBECONFIG="$PWD/kube/config"

kubectl wait pods \
  --for=condition=Ready \
  --all \
  --timeout=30s \
  --namespace cf
