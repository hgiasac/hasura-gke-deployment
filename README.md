# Hasura GKE K8s Stack

A feature-complete Hasura stack on GKE Kubernetes, for general k8s stack, [read here](https://github.com/hasura/hasura-k8s-stack)

## Components

- Google Cloud Services
- Cloud SQL Postgres Instance
- Hasura GraphQL Engine
- GKE Nginx Ingress
- Cert Manager for auto SSL with Let's Encrypt
- Google Cloud Deployment Manager (optional)

## Infrastructure 

### Google Cloud Services

- Create project
- Install [Google Cloud SDK](https://cloud.google.com/sdk/install)
- Enable APIs and Billing


### All-in-one script

You can run bash script to set up both Cloud SQL and Kubernetes with Deployment Manager, or skip this section if do manual configuration 

Set below environment variables, then run bash script

```bash

# Set variable for configration
export PROJECT_NAME=hasura-demo
export DB_INSTANCE_NAME=$PROJECT_NAME-pg
export DB_USER=hasura
export DB_PASSWORD=123456
export DB_NAME=hasura
export REGION=us-central1
export ZONE=us-central1-a
export DB_TIER=db-custom-1-3840

sh deployment-manager/deploy.sh

```

### Cloud SQL

Create a Cloud SQL instance on [Google Console](https://console.cloud.google.com/sql/instances), or using gcloud command / Deployment Manager. Here I use Deployment Manager to deploy Cloud SQL (and Kubernetes later)

Edit instance config `deployment-manager/postgres.yaml`, then run

```bash
gcloud deployment-manager deployments create hasuradb --config=deployment-manager/postgres.yaml
```

### Kubernetes

Create a GKE cluster on  [Google Console](https://console.cloud.google.com/sql/instances), or using gcloud command / Deployment Manager.

Edit instance config `deployment-manager/gke.yaml`, then run

``` bash
export GKE_NAME_NS=hasura-k8s
export ZONE=us-central1-a

gcloud deployment-manager deployments create $GKE_NAME_NS --config=deployment-manager/postgres.yaml
```

Then retrieve kubernetes cluster credentials for kubectl connection

```bash
gcloud container clusters get-credentials $GKE_NS-hasura-gke --zone $ZONE
```

## Kubernetes Setup

### Cloud SQL Proxy

The Cloud SQL Proxy provides secure access to your Cloud SQL Second Generation instances without having to whitelist IP addresses or configure SSL. For kubernetes, we will deploy (gce-proxy)[gcr.io/cloudsql-docker/gce-proxy:1.14] container.

Before that we have to prepare service account credential, stored in k8s secret.

- Create a service account on console, with Cloud SQL Admin role
- Download credential JSON file to local machine
- Create secret from file

```bash
export CLOUDSQL_SA_SECRET=cloudsql-instance-credentials

kubectl create secret generic $CLOUDSQL_SA_SECRET --from-file="credentials.json=/path/to/file.json"
```

- Edit instance connection name `{{connectionName}}` and secret mount point if you define another name on `cloud-sql/cloudsql-proxy.yaml`, then run deploy

```bash
kubectl apply -f cloud-sql/cloudsql-proxy.yaml
```
- Also create Postgres login credential secret for GraphQL Engine deployment `cloud-sql/cloudsql-db-credentials.yaml`

```bash
# edit template file first
kubectl apply -f cloud-sql/cloudsql-db-credentials.yaml

# or run script, with environment variables defined before
export DB_SECRET_NAME=cloudsql-db-credentials
sh cloud-sql/cloudsql-db-credentials.sh
```

### GraphQL Engine

Create Admin secret for security

```bash
# edit first
kubectl apply -f hasura/hasura-credentials.yaml

# or run script with env
HASURA_GRAPHQL_ADMIN_SECRET=hasura sh hasura/hasura-credentials.sh
```

All secret configs are ready. The remain step is deploying GraphQL Engine container and service

```bash
# hasura
kubectl apply -f hasura/graphql-engine.yaml
# hasura-svc
kubectl apply -f hasura/svc.yaml
```

### Ingress and HTTPS

Note: GKE now has beta support for natively provisioning Let's Encrypt TLS certificates. This demo uses GKE Ingress and [Google-managed SSL certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs)

**Prerequisites:**

- Domain name
- Create external IP address named e.g `hasura-gke-ip`

```
gcloud compute addresses create hasura-gke-ip --global
```

Create a ManagedCertificate resource. This resource specifies the domain that the SSL certificate will be created for. This demo use name `hasura-cert`

```bash
# change domain config
kubectl apply -f ingress/hasura-cert.yaml
```

Create Ingress, linked with ManagedCertificate `hasura-cert` and IP `hasura-gke-ip`

```bash
kubectl apply -f ingress/hasura-ingress.yaml
```

Configure DNS records for your domain to point to the IP address of the load balancer. You can get the IP on console, or gcloud command:

```bash
gcloud compute addresses describe $EIP_NAME --global
```


Now you can connect to Graphql Engine on the domain.

For SSL, we need to wait for the managed certificate to be provisioned. This may take up to 15 minutes. You can check on the status of the certificate with the following command:

```bash
kubectl describe managedcertificate
```

Once a certificate is successfully provisioned, the value of the `Status.CertificateStatus` field will be `Active`. 

> Note: Ingress enforces health check to ensure the service is always avaiable. We have to add `readinessProbe` config on [GraphQL Engine deployment template](hasura/graphql-engine.yaml)

```yaml
readinessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 5
```
