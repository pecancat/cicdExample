provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "default"
  region                  = "us-east-2"
}


resource "tls_private_key" "private-key" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}


resource "aws_key_pair" "deployer" {
  key_name   = "${terraform.workspace}.1.deployer-key"
  public_key = tls_private_key.private-key.public_key_openssh
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = ["Hello-World-SG"]
  tags = {
    Name = "Tomcat"
  }
 
  provisioner "remote-exec" {
    connection {
      host = self.public_ip
      user = "ubuntu"
      type = "ssh"
      private_key = tls_private_key.private-key.private_key_pem
    }
    
    inline = [
        "sudo apt-get install software-properties-common",
        "sudo apt-add-repository universe",
        "sudo apt-add-repository ppa:ansible/ansible -y",
        "sudo apt-get update -y",
        "sudo apt-get install git -y",
        "sudo apt-get install maven -y",
        "sudo apt-get install tomcat9 -y",
        "sudo ufw allow 8080",
        "sudo apt-get install ansible -y"
    ]    
  }

  provisioner "local-exec" {
    command = "terraform output private-key | sed '1d' | sed '28d' | sed '28d' > ~/.ssh/tomcat.pem; chmod 600 ~/.ssh/tomcat.pem"
  }
}

