# Create EC2 Instance
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
  provisioner "file" {
    source      = "aws/script_deploy.sh"
    destination = "/tmp/script_deploy.sh"
  }  
  provisioner "file" {
    source      = "private-key/id_rsa"
    destination = "/tmp/id_rsa"
  }  
  provisioner "file" {
    source      = "private-key/id_rsa.pub"
    destination = "/tmp/id_rsa.pub"
  }  

  # Ejecutamos los comandos para instalar las tools
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "cp /tmp/script_deploy.sh /home/ec2-user",
      "chmod +x /home/ec2-user/script_deploy.sh",
      "curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin",
      "echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc",
      "kubectl version --short --client",
      "sudo mkdir /root/.aws",
      "sudo cp /tmp/config /root/.aws/",
      "sudo cp /tmp/credentials /root/.aws/",
      "mkdir ~/.aws",
      "mv /tmp/config ~/.aws",
      "mv /tmp/credentials ~/.aws",
      "sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64", #ArgoCDInstall
      "sudo chmod +x /usr/local/bin/argocd",
      "sudo yum install -y jq",
      "sleep 30",
      "sudo docker ps",
      "sudo docker cp /tmp/Ec2-ssh-key.pem Jenkins:/tmp/Ec2-ssh-key.pem",
      "sudo docker exec -uroot Jenkins  chmod 400 /tmp/Ec2-ssh-key.pem"
    ]
  }


  provisioner "remote-exec" {
    inline = [
      "aws eks --region us-east-1 update-kubeconfig --name eks-cluster-dev",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml", #Para crear el IngressConroler
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl apply -n kube-system -f /tmp/dash_account.yaml ",
      "kubectl create namespace kubernetes-dashboard",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml",
      "echo \"TOKEN DASHBOARD\" >> dev.txt",
      "kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') >> dev.txt",
      "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'",
      "sleep 160",
      "export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`",
      "echo \"ARGO SERVER\" ",
      "echo $ARGOCD_SERVER",
      "export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d`",
      "echo \"ARGO PWD\" ",
      "echo $ARGO_PWD",
      "argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure",
      "echo \"ARGOCD_SERVER\" >> dev.txt",
      "echo $ARGOCD_SERVER >> dev.txt",
      "echo \"ARGO_PWD\" >> dev.txt",
      "echo $ARGO_PWD >> dev.txt",
      "cat dev.txt",
      "argocd app create ms-product --repo ${var.argo-ms-product-repo}    --revision Dev --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-payments --repo ${var.argo-ms-payments-repo}  --revision Dev --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-orders --repo ${var.argo-ms-orders-repo}      --revision Dev --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-shipping --repo ${var.argo-ms-shipping-repo}  --revision Dev --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "kubectl get ingress"
    ]
  }




  # Ejecutamos los comandos para instalar los deployment en cada cluster
  provisioner "remote-exec" {
    inline = [
      "aws eks --region us-east-1 update-kubeconfig --name eks-cluster-test",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml", #Para crear el IngressConroler
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl apply -n kube-system -f /tmp/dash_account.yaml ",
      "kubectl create namespace kubernetes-dashboard",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml",
      "echo \"TOKEN DASHBOARD\" >> test.txt",
      "kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') >> test.txt",
      "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'",
      "sleep 160",
      "export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`",
      "echo \"ARGO SERVER\" ",
      "echo $ARGOCD_SERVER",
      "export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d`",
      "echo \"ARGO PWD\" ",
      "echo $ARGO_PWD",
      "argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure",
      "echo \"ARGOCD_SERVER\" >> test.txt",
      "echo $ARGOCD_SERVER >> test.txt",
      "echo \"ARGO_PWD\" >> test.txt",
      "echo $ARGO_PWD >> test.txt",
      "cat test.txt",
      "argocd app create ms-product --repo ${var.argo-ms-product-repo}    --revision Test --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-payments --repo ${var.argo-ms-payments-repo}  --revision Test --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-orders --repo ${var.argo-ms-orders-repo}      --revision Test --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-shipping --repo ${var.argo-ms-shipping-repo}  --revision Test --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "kubectl get ingress"
    ]
  }


# Ejecutamos los comandos para instalar los deployment en cada cluster
  provisioner "remote-exec" {
    inline = [
      "aws eks --region us-east-1 update-kubeconfig --name eks-cluster-prod",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml", #Para crear el IngressConroler
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl apply -n kube-system -f /tmp/dash_account.yaml ",
      "kubectl create namespace kubernetes-dashboard",
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml",
      "echo \"TOKEN DASHBOARD\" >> prod.txt",
      "kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}') >> prod.txt",
      "kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'",
      "sleep 160",
      "export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`",
      "echo \"ARGO SERVER\" ",
      "echo $ARGOCD_SERVER",
      "export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d`",
      "echo \"ARGO PWD\" ",
      "echo $ARGO_PWD",
      "argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure",
      "echo \"ARGOCD_SERVER\" >> prod.txt",
      "echo $ARGOCD_SERVER >> prod.txt",
      "echo \"ARGO_PWD\" >> prod.txt",
      "echo $ARGO_PWD >> prod.txt",
      "cat prod.txt",
      "argocd app create ms-product --repo ${var.argo-ms-product-repo}    --revision Prod --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-payments --repo ${var.argo-ms-payments-repo}  --revision Prod --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-orders --repo ${var.argo-ms-orders-repo}      --revision Prod --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "argocd app create ms-shipping --repo ${var.argo-ms-shipping-repo}  --revision Prod --path . --dest-namespace default --sync-policy auto --dest-server https://kubernetes.default.svc",
      "kubectl get ingress"
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
