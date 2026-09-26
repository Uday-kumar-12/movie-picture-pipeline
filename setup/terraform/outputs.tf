output "aws_region" {
  description = "The AWS region where resources are deployed"
  value       = var.aws_region
}

output "eks_cluster_name" {
  description = "The name of the provisioned EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "frontend_ecr_repository_url" {
  description = "The URL of the frontend Amazon ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository_url" {
  description = "The URL of the backend Amazon ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "github_actions_iam_user" {
  description = "IAM user created for GitHub Actions deployment"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_access_key_id" {
  description = "Access key ID for GitHub Actions (configure as AWS_ACCESS_KEY_ID)"
  value       = aws_iam_access_key.github_actions_key.id
}

output "github_actions_secret_access_key" {
  description = "Secret access key for GitHub Actions (configure as AWS_SECRET_ACCESS_KEY)"
  value       = aws_iam_access_key.github_actions_key.secret
  sensitive   = true
}
