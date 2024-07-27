#!/bin/bash

# Set the resource type you want to destroy and rebuild
RESOURCE_TYPE="aws_lambda_function"

# Initialize Terraform
cd terraform && terraform init

# Get the list of resources to destroy
RESOURCES=$(terraform state list | grep ${RESOURCE_TYPE})

if [ -z "$RESOURCES" ]; then
    echo "No resources found of type ${RESOURCE_TYPE}."
    exit 0
fi

# Destroy the resources
echo "Destroying resources of type ${RESOURCE_TYPE}..."
for RESOURCE in $RESOURCES; do
    terraform destroy -target=${RESOURCE} -auto-approve
done

# Apply the configuration to rebuild the resources
echo "Rebuilding resources of type ${RESOURCE_TYPE}..."
terraform apply -auto-approve

echo "Successfully destroyed and rebuilt Lambda functions"
