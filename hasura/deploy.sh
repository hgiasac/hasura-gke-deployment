#! /bin/bash

echo "Creating GraphQL Engine admin secret.............."
sh ./hasura-credentials.sh

echo "Deploying GraphQL Engine............."
kubectl apply -f ./graphql-engine.yaml
kubectl apply -f ./svc.yaml
