#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "Movie Picture Pipeline - Infrastructure Init Script"
echo "=================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "Error: aws CLI is required but not installed." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Error: terraform is required but not installed." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl is required but not installed." >&2; exit 1; }

echo "Checking AWS caller identity..."
aws sts get-caller-identity

echo "Initializing Terraform..."
cd "${TERRAFORM_DIR}"
terraform init

echo "Validating Terraform configuration..."
terraform validate

echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Retrieving Terraform outputs..."
REGION=$(terraform output -raw aws_region)
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
FRONTEND_ECR=$(terraform output -raw frontend_ecr_repository_url)
BACKEND_ECR=$(terraform output -raw backend_ecr_repository_url)
ACCESS_KEY_ID=$(terraform output -raw github_actions_access_key_id)
SECRET_ACCESS_KEY=$(terraform output -raw github_actions_secret_access_key)

echo "Updating kubeconfig for EKS cluster: ${CLUSTER_NAME} in ${REGION}..."
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER_NAME}"

echo "=================================================="
echo "Infrastructure Setup Complete!"
echo "=================================================="
echo "Configure the following GitHub Secrets in your repository:"
echo "  AWS_ACCESS_KEY_ID:        ${ACCESS_KEY_ID}"
echo "  AWS_SECRET_ACCESS_KEY:    [SENSITIVE - See terraform output]"
echo "  AWS_REGION:               ${REGION}"
echo "  EKS_CLUSTER_NAME:         ${CLUSTER_NAME}"
echo "  ECR_FRONTEND_REPOSITORY:  ${FRONTEND_ECR}"
echo "  ECR_BACKEND_REPOSITORY:   ${BACKEND_ECR}"
echo "=================================================="
