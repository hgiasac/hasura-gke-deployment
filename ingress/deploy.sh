#!/bin/bash

EIP_NAME=${EIP_NAME:-hasura-gke-ip}
CERT_NAME=${CERT_NAME:-hasura-cert}

echo "Create external IP"
gcloud compute addresses create $EIP_NAME --global

echo "Create Certificate Manager"
cert_template=`cat "hasura-cert.yaml" | sed "s/{{certName}}/$CERT_NAME/g;s/{{domainName}}/$DOMAIN_NAME/g"`

echo "$cert_template" | kubectl apply -f -

echo "Create Ingress"
ingress_template=`cat "hasura-ingress.yaml" | sed "s/{{certName}}/$CERT_NAME/g;s/{{ipName}}/$EIP_NAME/g"`

echo "$ingress_template" | kubectl apply -f -
