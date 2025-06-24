#!/bin/bash

# Cloud Run Deployment Script for Bacon13 App
# Make sure you have gcloud CLI installed and authenticated

set -e

# Configuration
PROJECT_ID=${1:-"bacon13"}
REGION=${2:-"us-central1"}
ENVIRONMENT=${3:-"dev"}

echo "Deploying Bacon13 App to Cloud Run..."
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    containerregistry.googleapis.com \
    sql-component.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com

# Deploy infrastructure with Terraform
echo "Deploying infrastructure with Terraform..."
cd infrastructure

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    terraform init
fi

# Create terraform.tfvars file
cat > terraform.tfvars << EOF
project_id = "$PROJECT_ID"
region = "$REGION"
environment = "$ENVIRONMENT"
EOF

# Plan and apply
terraform plan
echo "Do you want to apply the Terraform configuration? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    terraform apply -auto-approve
else
    echo "Deployment cancelled."
    exit 1
fi

cd ..

# Build and deploy services
SERVICES=("auth-service" "user-service" "post-service")

for SERVICE in "${SERVICES[@]}"; do
    echo "Building and deploying $SERVICE..."
    
    # Build the image
    gcloud builds submit \
        --tag gcr.io/$PROJECT_ID/$SERVICE:latest \
        backend/$SERVICE/
    
    # Deploy to Cloud Run
    gcloud run deploy $SERVICE \
        --image gcr.io/$PROJECT_ID/$SERVICE:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 8080 \
        --memory 512Mi \
        --cpu 1 \
        --max-instances 10 \
        --set-cloudsql-instances $PROJECT_ID:$REGION:bacon13-app-$ENVIRONMENT \
        --set-env-vars "PROJECT_ID=$PROJECT_ID,ENVIRONMENT=$ENVIRONMENT"
done

echo "Deployment completed!"
echo ""
echo "Service URLs:"
for SERVICE in "${SERVICES[@]}"; do
    URL=$(gcloud run services describe $SERVICE --region=$REGION --format="value(status.url)")
    echo "$SERVICE: $URL"
done

echo ""
echo "To view logs:"
echo "gcloud logs read --project=$PROJECT_ID --filter='resource.type=cloud_run_revision'"
