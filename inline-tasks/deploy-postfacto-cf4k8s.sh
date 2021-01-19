#!/bin/bash
set -euo pipefail

export KUBECONFIG="$PWD/kube/config"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/kube/service-account.json"

redis_password="$(cat redis-password/password)"
values=eirini-private-config/environments/kube-clusters/cf4k8s4a8e/default-values.yml
cf_domain="$(goml get -f "$values" -p "system_domain")"
cf_admin_password="$(goml get -f "$values" -p "cf_admin_password")"

unzip postfacto/package.zip -d postfacto/
cp eirini-private-config/postfacto-deployment/api/config.js postfacto/package/assets/client/

sed -i "s/ruby '2.6.3'.*$//" postfacto/package/assets/Gemfile
sed -i "s/ruby 2.6.3p62.*$//" postfacto/package/assets/Gemfile.lock
sed -i "34igem 'therubyracer'" postfacto/package/assets/Gemfile
sed -i "34igem 'execjs'" postfacto/package/assets/Gemfile

# echo "web:  bundle exec rake db:migrate && bundle exec rails s -p \$PORT -e development" >postfacto/package/assets/Procfile
rm postfacto/package/assets/.ruby-version

sed -i "32i  config.hosts << 'retro.${cf_domain}'" postfacto/package/assets/config/environments/development.rb
sed -i "32i  config.hosts << 'retro.eirini.cf'" postfacto/package/assets/config/environments/development.rb

cf api "api.$cf_domain" --skip-ssl-validation
cf auth admin "$cf_admin_password"
cf create-org postfacto
cf create-space -o postfacto postfacto
cf target -o postfacto -s postfacto

cf push -f eirini-private-config/postfacto-deployment/api/manifest-cf4k8s4a8e.yml \
  -p postfacto/package/assets \
  --var api-app-name=postfacto-api \
  --var pcf-url="${cf_domain}" \
  --var domain="${cf_domain}" \
  --var namespace=postfacto-redis \
  --var redis-password="${redis_password}" \
  --var mysql-address="$MYSQL_ADDRESS" \
  --var mysql-password="((mysql-password))" \
  --no-start

cf share-private-domain postfacto eirini.cf
cf map-route postfacto-api eirini.cf --hostname retro
cf start postfacto-api

admin_user="((admin-user))"
admin_password="((admin-password))"
cf run-task postfacto-api -c "ADMIN_EMAIL=$admin_user ADMIN_PASSWORD=$admin_password 'rake admin:create_user'"
