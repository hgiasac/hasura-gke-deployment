#! /bin/bash

echo "Creating DB Credential Secrets..."
sh ./cloudsql-db-credentials.sh

echo "Deploying Cloud SQL Proxy..."

# get instance connection name 
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME | grep connectionName | awk '{print $2}')
proxy_template=`cat "cloudsql-proxy.yaml" | sed "s/{{connectionName}}/$CONNECTION_NAME/g"`

# apply the yml with the substituted value
echo "$proxy_template" | kubectl apply -f -
