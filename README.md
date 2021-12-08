
# Obligatorio Certificacion DevOps :rocket:

Integrantes del equipo: [Jorge González  ](https://github.com/jorgon183)[, Aroldo Navarro  ](https://github.com/aroldonq)[, Federico Mastrángelo](https://github.com/2matra2/)

## Implementacion modelo DevOps

Que es DevOps:interrobang:

DevOps en escencia son un conjunto de metodologias y practicas que agrupan el desarrollo
de software y  la operaciones TI, destinadas a agilizar el ciclo de vida del desarrollo de 
software proporcionando una alta calidad en la entrega continua del mismo. DevOps busca
la entrega de funcionalidades al usuario lo mas rapido posible sin sacrificar la calidad del 
producto.




**La implementacion de este obligatorio consta de 3 Puntos clave:**

- **La utilizacion de un repositorio para versionado y gestion de codigo.**
- **La creacion de la Infraestructura Como Codigo.**
- **La implementacion de un canal CI/CD.**


## IaC:computer:

Para la creacion de la infraestructura cloud se utilizara la herramienta de aprovisionamiento de infraestructura *Terraform*, junto con el proveedor **Amazon Web Services** en el cual se desplegarán clusters de *Kubernetes* utilizando el servicio **EKS** (Elastic Kubernetes Service)

Los archivos de el proyecto son manejados en el siguiente repositorio:
[Repo Terraform](https://github.com/devopsort/terraform.git)  (En la rama "Prod").


**Antes de iniciar se debe crearse manualmente un bucket S3 "terraform-devops-obligatorio" para poder almacenar el remote terraform state file.** 

![Bucket S3](Images/Bucket.png)


**- Se declaran los providers a utilizar para crear la infraestructura junto con el bucket s3**

```terraform
# Terraform Block -c1-versions.tf
terraform {
  #required_version = "~> 0.14.6" # which means >= 0.14.6 and < 0.15
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    /*
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    */
  }

  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-devops-obligatorio3"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}


# Provider Block
provider "aws" {
  region  = var.aws_region   //"us-east-1"
  profile = "default"
}

//provider "kubernetes" {}
```

**- Debe crearse un par de claves ssh, descargar el pem y colocarlo en la carpeta "private-key", configurar el mismo en el archivo de variables y terraform.tfvars.**

```terraform
# Variables Generales -variables.tf
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
```

```terraform
# Variables Generales -terraform.tfvars
aws_region = "us-east-1"
terraform-key = "keyssh-EC2-prueba"
Ec2-ssh-key = "private-key/keyssh-EC2-prueba-insite.pem"
````

**La infraestructura contsa de tres ambientes conformados por:**

- Un VPC con diferenets SubNet para los ambientes:
  - SubNet infraestructura: una zona de disponibilidad.
  - SubNet Developer dos zonas a y b
  - SubNet Testing dos zonas a y b 
  - SubNet Prod cuatro zonas a, b, c y d.

```terraform
# Resources Block -c2-vpc.tf
# Resource-1: Create VPC
resource "aws_vpc" "vpc-obligatorio" {
  cidr_block = var.VPC_cidr_block //"10.0.0.0/16"
  tags = {
    "Name" = "vpc-obligatorio"
  }
}


resource "aws_subnet" "vpc-subnets-obl" {
  vpc_id            = aws_vpc.vpc-obligatorio.id
  for_each = var.subnet_data
    availability_zone = each.value.availability_zone
    map_public_ip_on_launch = true
    cidr_block        = each.value.cidr_block
    tags = each.value.tags
}


# Resource-3: Internet Gateway
resource "aws_internet_gateway" "vpc-obligatorio-igw" {
  vpc_id = aws_vpc.vpc-obligatorio.id
}

# Resource-4: Create Route Table
resource "aws_route_table" "vpc-obligatorio-public-route-table" {
  vpc_id = aws_vpc.vpc-obligatorio.id
}

# Resource-5: Create Route in Route Table for Internet Access
resource "aws_route" "vpc-obligatorio-public-route" {
  route_table_id         = aws_route_table.vpc-obligatorio-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-obligatorio-igw.id
}

# Resource-6: Associate the Route Table with the Subnet a
resource "aws_route_table_association" "vpc-obligatorio-frontend-route-table-associate" {
  for_each = var.subnet_data
    route_table_id = aws_route_table.vpc-obligatorio-public-route-table.id
    subnet_id      = aws_subnet.vpc-subnets-obl[each.key].id
    
}
```

```terraform
# Variables VPC -terraform.tfvars
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
    S2-Sub_test-a = {
      availability_zone = "us-east-1a"
      cidr_block = "10.0.20.0/24"
      tags = {
        Name = "Subnet test a"
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
    S8-Sub_infra = {
      availability_zone = "us-east-1f"
      cidr_block = "10.0.200.0/24"
      tags = {
        Name = "Subnet Infra"
        terraform   = "true"
      }      
    }    
  }
```
- **Segurity groups para cada ambiente.**
    - En la SubNet de infra se permite el acceso por el puerto 22(SSH) y al Jenkins por el 8080.
    - En las subnet de los ambientes se les permiten todos los puertos desde dentro de la infraestructura, desde fuera por internet solo 80 y 443, para publicar los         servicios.


![Github logo](terraform/Images/SG DEVELOPER.png)



- **Cada ambiente consta de un cluster de EKS**:
  - eks-cluster-dev 
  - eks-cluster-test
  - eks-cluster-prod
    
    
Los mismos estan parametrizados en el archivo de variables.tfvars, asi como los recursos a cada uno.



```terraform
#Cluster EKS Developer -eksCluster.tf
#--------------------------------------------------------------------------------
resource "aws_eks_cluster" "eks-cluster-obl" {
  role_arn = aws_iam_role.eks-cluster-role.arn

  for_each = var.EKS_Cluster
  //count = length(var.EKS_Cluster)
    vpc_config {
      //subnet_ids      = [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id]
      subnet_ids = each.value.name == "eks-cluster-prod"   ? [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id] : (each.value.name == "eks-cluster-test"   ? [values(aws_subnet.vpc-subnets-obl)[2].id, values(aws_subnet.vpc-subnets-obl)[3].id] : [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id] )
      security_group_ids = each.value.name == "eks-cluster-prod"   ? [aws_security_group.sg-obl-eks-prod.id] : (each.value.name == "eks-cluster-test"   ? [aws_security_group.sg-obl-eks-test.id] : [aws_security_group.sg-obl-eks-dev.id] )
      //security_group_ids = [aws_security_group.sg-obl-eks-dev.id]
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

/*
output "endpoint" {
  value = [aws_eks_cluster.eks-cluster-obl.endpoint]
}


output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks-cluster-obl.certificate_authority[0].data
}




#Node Groups
resource "aws_eks_node_group" "node_group-obl-dev" {
  for_each = var.EKS_Cluster
  cluster_name    = aws_eks_cluster.eks-cluster-obl[each.key].name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.eks-node-group-role.arn
//      subnet_ids      = [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id]
    subnet_ids = each.value.name == "eks-cluster-prod"   ? [values(aws_subnet.vpc-subnets-obl)[4].id, values(aws_subnet.vpc-subnets-obl)[5].id, values(aws_subnet.vpc-subnets-obl)[6].id, values(aws_subnet.vpc-subnets-obl)[7].id] : (each.value.name == "eks-cluster-test"   ? [values(aws_subnet.vpc-subnets-obl)[2].id, values(aws_subnet.vpc-subnets-obl)[3].id] : [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id] )
    //remote_access_security_group_id = each.value.name == "eks-cluster-prod"   ? [aws_security_group.sg-obl-eks-prod.id] : (each.value.name == "eks-cluster-test"   ? [aws_security_group.sg-obl-eks-test.id] : [aws_security_group.sg-obl-eks-dev.id] )
  

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
```

```terraform
# Variables EKS Cluster -terraform.tfvars
Eks_Namespace 		= "default"
Eks_instance_types	= ["t3.medium"]

EKS_Cluster ={
    
    Eks_Cl_Dev = {
      name = "eks-cluster-dev"
      node_group_name = "node_group-obl-dev"
      desired_size = 2
      max_size     = 2
      min_size     = 2
      //subnet_ids = [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id]
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
      //subnet_ids = [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id]
      tags = {
        Name = "Cluster Test"
        terraform   = "true"
      }      
    } ,
    Eks_Cl_Prod = {
      name = "eks-cluster-prod"
      node_group_name = "node_group-obl-prod"
      desired_size = 4
      max_size     = 8
      min_size     = 2
      //subnet_ids = [values(aws_subnet.vpc-subnets-obl)[0].id, values(aws_subnet.vpc-subnets-obl)[1].id]
      tags = {
        Name = "Cluster Prod"
        terraform   = "true"
      }  
    } 
  }
  ```








- Una Instancia EC2 "JenkinsDockerTF" con el SecurityGroup **"sg-obl-infra"** y la SubNet **"Subnet Infra"**
  - Esta instancia cumplira la funcion de administrar Jenkins, kubectl, aws_cli y argo_cli.
  - Se le instalaran todas las herramientas necesarias mediante remote-exec
 
  
 
 ```terraform
# Create EC2 Instance  -Jenkins.tf
resource "aws_instance" "JenkinsDockerTF" {
	ami = "ami-02e136e904f3da870"
	instance_type = var.Jenkins_instance_type
	key_name = var.terraform-key
	subnet_id   = values(aws_subnet.vpc-subnets-obl)[8].id
  vpc_security_group_ids = [aws_security_group.sg-obl-infra.id]  
  private_ip = var.JenkinsIP


  #Bloque de conexion SSH para poder conectarse por SSH y ejecutar el provisioner
  connection {
    type = "ssh"
    host = self.public_ip # Understand what is "self"
    user = "ec2-user"
    password = ""
    private_key = file(var.Ec2-ssh-key)
  }  

 # Copiamos el script para inicializar la base de datos
  provisioner "file" {
    source      = "${var.Ec2-ssh-key}"
    destination = "/tmp/Ec2-ssh-key.pem"
  }
  provisioner "file" {
    source      = "aws/config"
    destination = "/tmp/config"
  }
  provisioner "file" {
    source      = "aws/credentials"
    destination = "/tmp/credentials"
  }
  provisioner "file" {
    source      = "aws/dash_account.yaml"
    destination = "/tmp/dash_account.yaml"
  }

  # Ejecutamos los comandos para instalar las tools
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin",
      "echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc",
      "kubectl version --short --client",
      "mkdir /root/.aws",
      "cp /tmp/config /root/.aws/",
      "cp /tmp/credentials /root/.aws/",
      "mkdir ~/.aws",
      "mv /tmp/config ~/.aws",
      "mv /tmp/credentials ~/.aws",
      "aws ec2 describe-instances",
      "sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64", #ArgoCDInstall
      "sudo chmod +x /usr/local/bin/argocd",
      "sudo yum install -y jq",
      "sleep 30",
      "sudo docker ps",
      "sudo docker cp /tmp/Ec2-ssh-key.pem Jenkins:/tmp/Ec2-ssh-key.pem",
      "sudo docker exec -uroot Jenkins  chmod 400 /tmp/Ec2-ssh-key.pem"
    ]
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y yum-utils
              sudo yum install -y docker
              sudo yum install -y git
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo mkdir /home/jenkins_home
              sudo chmod -R 777 /home/jenkins_home
              sudo mkdir var/registry
              sudo docker run --name Jenkins --add-host=JenkinsDockerTF:${var.JenkinsIP} -d --restart unless-stopped -p 8080:8080 -p 50000:50000 -v /home/jenkins_home:/var/jenkins_home jenkins/jenkins:lts-jdk11
            EOF   
	tags = {
		Name = "JenkinsDockerTF"	
		Batch = "Docker, kubectl, argocd"
	}
  depends_on = [aws_eks_cluster.eks-cluster-obl,aws_eks_node_group.node_group-obl-dev]
}
```

- Un conjunto de repositorios ECR para almacenar las imagenes buildeadas de cada microservicio



Luego de instalada la Infraestructura nos logueamos al EC2 de Jenkins para proceder con la configuración del mismo, lo primero es buscar el `initialAdminPassword` que solicita el Jenkins para inicializarlo, ver imagen:

![Jenkins_0](Images/Screenshot_0.png)

 Especificamos la clave mostrada anteriormente en la nuestra interfaz Jenkins, ver imagen:

![Jenkins_1](Images/Screenshot_1.png)


Luego procedemos a la instalacion de las dependencias iniciales que nos especifica el Jenkins por defecto y a la configuración del usuario `Admininistrador` que se va a usar, ver imagen:

![Jenkins_2](Images/Screenshot_2.png)
![Jenkins_3](Images/Screenshot_3.png)

Y como bien se muestra en la siguiente imagen, se puede mostrar que la instalación termino exitosamente y que esta operativo y listo para trabajar.

![Jenkins_4](Images/Screenshot_4.png)

Para el despliegue y la compilación del los microservicios configuramos las diferentes tareas para gestionar el trabajo.
En el siguiente Job capturamos el evento cuando se realice el push por parte de desarrollador en las ramas del git.
Primeramente especificamos el repositorio del microservicio:

**Nota:** Se toma como ejemplo el repositorio del microservicio **products**.

![Jenkins_5](Images/Screenshot_5.png)

Además guardamos en un archivo variable el repo y la rama de la cual se realiza el commit y llamamos a otro Jobs que va ser el encargado de hacer el armado de la imagen, el push para el ECR de AWS y el despliegue en los K8S de los diferentes microservicios.

![Jenkins_6](Images/Screenshot_6.png)

Especificacion del jobs **OBLIGATORIO**:

![Jenkins_8](Images/Screenshot_8.png)

Al final de la configuración las tareas quedan de la siguiente manera:

![Jenkins_7](Images/Screenshot_7.png)

Por ultimo se debe especificar en el las configuraciones del git la url del jenkins para asociarlo, ver imagen:

![Jenkins_9](Images/Screenshot_9.png)

**Repositorio donde especificamos el archivo Jenkinsfile-Obligatorio:** 

`url:` https://github.com/devopsort/Pipelines.git







