# Variables Generales
variable "aws_region" {
  description = "Region in which AWS resources to be created"
  type        = string
}

variable "terraform-key" {
    description = "AWS ssh Key"
    type = string
    sensitive = true
}

variable "Ec2-ssh-key" {
    description = "SSH Key"
    type = string
    sensitive = true
}

variable "JenkinsIP" {
    description = "Jenkins private IP"
    type = string
    sensitive = true
}

variable "Jenkins_instance_type" {
    description = "Jenkins instance_type"
    type = string
    sensitive = true
}

# Variables VPC and Subnet
variable "VPC_cidr_block" {
  description = "VPC cidr block (10.0.1.0/24)"
  type        = string
}



variable "subnet_data" {
}


# Variables EKS Cluster
variable "Eks_Namespace" {
  description = "Namespace para el EKS"
  type        = string
}

variable "EKS_Cluster" {
}

variable "Eks_instance_types" {
  description = "instance_types para el node group de EKS"
}



# Variables ECR Repos
variable "ECR_Repos" {
  description = "Enumera los repositorios a crear para cada ms"
}

# Variables ms-product-repo
variable "argo-ms-product-repo" {
  description = "URL repo Argo ms-product"
  type        = string
}