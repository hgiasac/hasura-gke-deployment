#! bin/bash

# Set default variables
REGION=${REGION:-us-central1}
ZONE=${ZONE:-us-central1-a}
DB_TIER=${DB_TIER:-db-custom-1-3840}

# Create Cloud SQL Deployment
sql_tmpl="/tmp/sql_tmpl.yaml" 
sql_template=`cat "postgres.yaml" | sed "s/{{instanceName}}/$DB_INSTANCE_NAME/g;s/{{dbUser}}/$DB_USER/g; s/{{dbPassword}}/$DB_PASSWORD/g; s/{{dbName}}/$DB_NAME/g; s/{{dbTier}}/$DB_TIER/g; s/{{region}}/$REGION/g; s/{{zone}}/$ZONE/g"`

echo "$sql_template" > $sql_tmpl

echo "Installing Cloud SQL..."
gcloud deployment-manager deployments create $DB_INSTANCE_NAME --config $sql_tmpl

rm $sql_tmpl

# Create GKE Deployment

echo "Installing Google Kubernetes Engine..."
gke_tmpl="/tmp/gke_tmpl.yaml" 
gke_template=`cat "gke.yaml" | sed "s/{{zone}}/$ZONE/g"`

echo "$gke_template" > $sql_tmpl
gcloud deployment-manager deployments create $GKE_NAME_NS --config $sql_tmpl

rm $sql_tmpl

gcloud container clusters get-credentials "$GKE_NAME_NS-hasura-gke" --zone $ZONE
