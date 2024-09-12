output "kubernetes_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "_1_aws_kubeconfig_cmd" {
  description = "The aws command to run to load kubeconfig credentials"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks_cluster.name}\n"
}
