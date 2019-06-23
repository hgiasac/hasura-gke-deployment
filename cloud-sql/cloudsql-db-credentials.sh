#!/bin/bash

DB_SECRET_NAME=${DB_SECRET_NAME:-cloudsql-db-credentials}
DB_USER=`echo -n "$DB_USER" | base64`
DB_PASSWORD=`echo -n "$DB_PASSWORD" | base64`
DB_NAME=`echo -n "$DB_NAME" | base64`

# cloud SQL template
template=`cat "cloudsql-db-credentials.yaml" | sed "s/{{dbSecretName}}/$DB_SECRET_NAME/g;s/{{dbUser}}/$DB_USER/g; s/{{dbPassword}}/$DB_PASSWORD/g; s/{{dbName}}/$DB_NAME/g"`

# apply the yml with the substituted value
echo "$template" | kubectl apply -f -
