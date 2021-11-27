/*
data "aws_subnet_ids" "test_subnet_ids" {
  vpc_id = "vpc-obligatorio"

  depends_on = [
    aws_subnet.vpc-subnets-obl,
  ]
}


output subnet_infra_id {
  value = values(aws_subnet.vpc-subnets-obl)[3].id
}



resource "aws_network_interface" "eth_jenkins" {
  subnet_id   = values(aws_subnet.vpc-subnets-obl)[3].id
  private_ips = [var.JenkinsIP]

  tags = {
    Name = "eth_jenkins"
  }
}
*/

# Create EC2 Instance
resource "aws_instance" "JenkinsDockerTF" {
	ami = "ami-02e136e904f3da870"
	instance_type = var.Jenkins_instance_type
	key_name = var.terraform-key
	subnet_id   = values(aws_subnet.vpc-subnets-obl)[8].id

//    network_interface {
//      network_interface_id = aws_network_interface.eth_jenkins.id
//      device_index         = 0
//    }

    user_data = <<-EOF
              #!/bin/bash
              sudo yum install -y yum-utils
              sudo yum install -y docker
              sudo yum install -y git
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo mkdir /var/jenkins_home
              sudo mkdir var/registry
              sudo docker run --name Jenkins --add-host=JenkinsDockerTF:${var.JenkinsIP} -d --restart unless-stopped -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home jenkins/jenkins:lts-jdk11
              sudo docker run -d -v /var/registry:/var/lib/registry -p 5000:5000 --restart always --name registry registry:2
            EOF   
	tags = {
		Name = "JenkinsDockerTF"	
		Batch = "Docker"
	}
}
