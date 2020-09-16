#!/bin/bash
set -euxo pipefail

export KUBECONFIG="$PWD/kube/config"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"

unzip postfacto/package.zip -d postfacto/
cp eirini-private-config/postfacto-deployment/api/config.js postfacto/package/assets/client/
sed -i "s/ruby '2.6.3'/ruby '2.6.6'/" postfacto/package/assets/Gemfile
redis_password="$(cat redis-password/password)"
values=eirini-private-config/environments/kube-clusters/cf4k8s4a8e/default-values.yml
cf_domain="$(goml get -f "$values" -p "system_domain")"
cf_admin_password="$(goml get -f "$values" -p "cf_admin_password")"
cf api "api.$cf_domain" --skip-ssl-validation
cf auth admin "$cf_admin_password"
cf create-org postfacto
cf create-space -o postfacto postfacto
cf target -o postfacto -s postfacto

# domain="$(goml get -f "$values" -p "eirini.opi.ingress_endpoint")"
domain="$cf_domain"

if cf app postfacto-api; then
  cf rename postfacto-api postfacto-api-old
fi

cf push -f eirini-private-config/postfacto-deployment/api/manifest-cf4k8s4a8e.yml \
  -p postfacto/package/assets \
  --hostname retro-temp \
  -d "${domain}" \
  --var api-app-name=postfacto-api \
  --var pcf-url="${domain}" \
  --var domain="${domain}" \
  --var namespace=postfacto-redis \
  --var redis-password="${redis_password}" \
  --var mysql-address="$MYSQL_ADDRESS" \
  --var mysql-password="((mysql-password))"

curl --fail "https://retro-temp.${domain}"
cf map-route postfacto-api "${domain}" --hostname retro
cf unmap-route postfacto-api "${domain}" --hostname retro-temp

curl --fail "https://retro.${domain}"
if cf app postfacto-api-old; then
  cf unmap-route postfacto-api-old "${domain}" --hostname retro
  cf delete -f postfacto-api-old
fi
