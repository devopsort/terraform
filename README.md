
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

[IMAGEN BUCKET]


- Se declaran los providers a utilizar para crear la infraestructura junto con el bucket s3 

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

- Debe crearse un par de claves ssh, descargar el pem y colocarlo en la carpeta "private-key", configurar el mismo en el archivo de variables y terraform.tfvars.

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

La infraestructura contsa de tres ambientes conformados por:

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
- Se crearon Segurity groups para cada ambiente.
  - En la SubNet de infra se permite el acceso por el puerto 22(SSH) y al Jenkins por el 8080.
  - En las subnet de los ambientes se les permiten todos los puertos desde dentro de la infraestructura, desde fuera por internet solo 80 y 443, para publicar los         servicios.


























