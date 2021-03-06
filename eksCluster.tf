#Cluster EKS Developer
#--------------------------------------------------------------------------------
resource "aws_eks_cluster" "eks-cluster-obl" {
  role_arn = aws_iam_role.eks-cluster-role.arn

  for_each = var.EKS_Cluster
    vpc_config {
      subnet_ids = each.value.name == "eks-cluster-prod"   ? [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id] : (each.value.name == "eks-cluster-test"   ? [values(aws_subnet.vpc-subnets-obl)[2].id, values(aws_subnet.vpc-subnets-obl)[3].id] : [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id] )
      security_group_ids = each.value.name == "eks-cluster-prod"   ? [aws_security_group.sg-obl-eks-prod.id] : (each.value.name == "eks-cluster-test"   ? [aws_security_group.sg-obl-eks-test.id] : [aws_security_group.sg-obl-eks-dev.id] )
      endpoint_private_access   = true
      endpoint_public_access    = false
    }
    name    = each.value.name

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.pol-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.pol-AmazonEKSVPCResourceController,
  ]
}



#Node Groups
resource "aws_eks_node_group" "node_group-obl-dev" {
  for_each = var.EKS_Cluster
  cluster_name    = aws_eks_cluster.eks-cluster-obl[each.key].name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.eks-node-group-role.arn
    subnet_ids = each.value.name == "eks-cluster-prod"   ? [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id] : (each.value.name == "eks-cluster-test"   ? [values(aws_subnet.vpc-subnets-obl)[2].id, values(aws_subnet.vpc-subnets-obl)[3].id] : [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id] )
  

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }
  
  instance_types = var.Eks_instance_types

  update_config {
    max_unavailable = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_eks_cluster.eks-cluster-obl,
    aws_iam_role_policy_attachment.pol-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.pol-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.pol-AmazonEC2ContainerRegistryReadOnly,
  ]
}
