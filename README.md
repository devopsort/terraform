
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
   
  }

  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "terraform-devops-obligatorio"
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
    ....
```
- **Segurity groups para cada ambiente.**
    - En la SubNet de infra se permite el acceso por el puerto 22(SSH) y al Jenkins por el 8080.
    - En las subnet de los ambientes se les permiten todos los puertos desde dentro de la infraestructura, desde fuera por internet solo 80 y 443, para publicar los         servicios.


![Github logo](terraform/Images/SG DEVELOPER.png)



- **Cada ambiente consta de un cluster de EKS**:
  - eks-cluster-dev 
  - eks-cluster-test
  - eks-cluster-prod
    
    
Los mismos estan parametrizados en el archivo de variables.tfvars y eksCluster.tf asi como los recursos a cada uno.

tfvars:[ .tfvars](https://github.com/devopsort/terraform/blob/Prod/terraform.tfvars) 

ekscluster:[ ekscluster.tf](https://github.com/devopsort/terraform/blob/Prod/eksCluster.tf)




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
    ....
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
      ....
  ```




- Una Instancia EC2 "JenkinsDockerTF" con el SecurityGroup **"sg-obl-infra"** y la SubNet **"Subnet Infra"**
  - Esta instancia cumplira la funcion de administrar Jenkins, kubectl, aws_cli y argo_cli.
  - Se le instalaran todas las herramientas necesarias mediante remote-exec
  
  **El Codigo puede encontrarse en**: [Jenkins.tf](https://github.com/devopsort/terraform/blob/Prod/Jenkins.tf)
  
 

- Un conjunto de repositorios ECR para almacenar las imagenes buildeadas de cada microservicio


# CI/CD:computer:

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






