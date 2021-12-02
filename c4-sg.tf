# Resource-1: Create Security Group Infra
resource "aws_security_group" "sg-obl-infra" {
  name        = "infra-sg"
  description = "Infra Security Group"
  vpc_id      = aws_vpc.vpc-obligatorio.id

  ingress {
    description = "Allow Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
	tags = {
		Name = "infra-sg"	
	}
}


# Resource-2: Create Security for developer
resource "aws_security_group" "sg-obl-eks-dev" {
  name        = "eks-sg-dev"
  description = "EKS Security Group developer"
  vpc_id      = aws_vpc.vpc-obligatorio.id

  ingress {
    description = "Allow Port from Infra Subnet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.200.0/24", "10.0.10.0/24", "10.0.11.0/24"]
  }
  ingress {
    description = "Allow Port 80" //http Port frontend and backend
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 443" //https Port frontend and backend
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
	tags = {
		Name = "eks-sg-dev"	
	}  
}

# Resource-2: Create Security for test
resource "aws_security_group" "sg-obl-eks-test" {
  name        = "eks-sg-test"
  description = "EKS Security Group testing"
  vpc_id      = aws_vpc.vpc-obligatorio.id

  ingress {
    description = "Allow Port from Infra Subnet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.200.0/24", "10.0.20.0/24", "10.0.21.0/24"]
  }
  ingress {
    description = "Allow Port 80" //http Port frontend and backend
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 443" //https Port frontend and backend
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
	tags = {
		Name = "eks-sg-test"	
	}  
}


# Resource-2: Create Security for test
resource "aws_security_group" "sg-obl-eks-prod" {
  name        = "eks-sg-prod"
  description = "EKS Security Group Production"
  vpc_id      = aws_vpc.vpc-obligatorio.id

  ingress {
    description = "Allow Port from Infra Subnet"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.200.0/24", "10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
  ingress {
    description = "Allow Port 80" //http Port frontend and backend
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 443" //https Port frontend and backend
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
	tags = {
		Name = "eks-sg-prod"	
	}  
}