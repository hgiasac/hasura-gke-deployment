#! /bin/bash

echo "Removing GraphQL Engine deployments..."

kubectl delete -f svc.yaml
kubectl delete -f graphql-engine.yaml
kubectl delete secret hasura-credentials
