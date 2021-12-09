
# Variables Generales
aws_region = "us-east-1"
terraform-key = "keyssh-EC2-prueba"
Ec2-ssh-key = "private-key/keyssh-EC2-prueba-4.pem"

JenkinsIP = "10.0.200.10"
Jenkins_instance_type = "t2.micro"

# Variables VPC
VPC_cidr_block = "10.0.0.0/16"

subnet_data = {
    S0-Sub_dev-a = {
      availability_zone = "us-east-1a"
      cidr_block = "10.0.10.0/24"
      tags = {
        Name = "Subnet Dev a"
        terraform   = "true"
      }
    },
    S1-Sub_dev-b = {
      availability_zone = "us-east-1b"
      cidr_block = "10.0.11.0/24"
      tags = {
        Name = "Subnet Dev b"
        terraform   = "true"
      }      
    },
    S2-Sub_test-a = {
      availability_zone = "us-east-1a"
      cidr_block = "10.0.20.0/24"
      tags = {
        Name = "Subnet test a"
        terraform   = "true"
      }      
    },
    S3-Sub_test-b = {
      availability_zone =  "us-east-1b"
      cidr_block = "10.0.21.0/24"
      tags = {
        Name = "Subnet test b"
        terraform   = "true"
      }      
    },
    S4-Sub_prod_a = {
      availability_zone = "us-east-1a"
      cidr_block = "10.0.100.0/24"
      tags = {
        Name = "Subnet prod a"
        terraform   = "true"
      }      
    },
    S5-Sub_prod_b = {
      availability_zone = "us-east-1b"
      cidr_block = "10.0.101.0/24"
      tags = {
        Name = "Subnet prod b"
        terraform   = "true"
      }      
    },
    S6-Sub_prod_c = {
      availability_zone = "us-east-1c"
      cidr_block = "10.0.102.0/24"
      tags = {
        Name = "Subnet prod c"
        terraform   = "true"
      }      
    },
    S7-Sub_prod_d = {
      availability_zone = "us-east-1d"
      cidr_block = "10.0.103.0/24"
      tags = {
        Name = "Subnet prod d"
        terraform   = "true"
      }      
    },
    S8-Sub_infra = {
      availability_zone = "us-east-1f"
      cidr_block = "10.0.200.0/24"
      tags = {
        Name = "Subnet Infra"
        terraform   = "true"
      }      
    }    
  }


# Variables EKS Cluster
Eks_Namespace 		= "default"
Eks_instance_types	= ["t3.medium"]

EKS_Cluster ={
    Eks_Cl_Dev = {
      name = "eks-cluster-dev"
      node_group_name = "node_group-obl-dev"
      desired_size = 2
      max_size     = 2
      min_size     = 2
      tags = {
        Name = "Cluster dev"
        terraform   = "true"
      }
    }, 
    Eks_Cl_Test = {
      name = "eks-cluster-test"
      node_group_name = "node_group-obl-test"
      desired_size = 2
      max_size     = 2
      min_size     = 2
      tags = {
        Name = "Cluster Test"
        terraform   = "true"
      }      
    },
    Eks_Cl_Prod = {
      name = "eks-cluster-prod"
      node_group_name = "node_group-obl-prod"
      desired_size = 2
      max_size     = 8
      min_size     = 2
      tags = {
        Name = "Cluster Prod"
        terraform   = "true"
      }  
    }
  }


ECR_Repos = { 
    ECR_order = {
      name = "orders-service"
    },
    ECR_payments = {
      name = "payments-service"
    },
    ECR_products = {
      name = "products-service"
    },
    ECR_shipping = {
      name = "shipping-service"
    }
}

#Repositorios de ArgoCD
argo-ms-product-repo      = "https://github.com/devopsort/argocd_products-service-example.git"
argo-ms-payments-repo     = "https://github.com/devopsort/argocd_payments-service-example.git"
argo-ms-orders-repo       = "https://github.com/devopsort/argocd_orders-service-example.git"
argo-ms-shipping-repo     = "https://github.com/devopsort/argocd_shipping-service-example.git"
