#! /bin/bash

HASURA_SECRET=`echo -n "${HASURA_GRAPHQL_ADMIN_SECRET}" | base64`

# Hasura Secret template
hasura_secret_tmpl=`cat "hasura-credentials.yaml" | sed "s/{{adminSecret}}/$HASURA_SECRET/g"`

# apply the yml with the substituted value
echo "$hasura_secret_tmpl" | kubectl apply -f -
