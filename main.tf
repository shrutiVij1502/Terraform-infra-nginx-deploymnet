terraform {
  required_providers {
    aws = {
# version = ">= <Version you want to use>"
      source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# for vpc

resource "aws_vpc" "nginx-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"
}


# for subnet 

resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.nginx-vpc.id // Referencing the id of the VPC from abouve code block
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // Makes this a public subnet
  availability_zone       = "us-west-2a"
}


# internet gateway

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
}



# custom route table for vpc

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.nginx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"                      //associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.prod-igw.id //CRT uses this IGW to reach internet
  }
tags = {
    Name = "prod-public-crt"
  }
}

# Route table with public subnet  - association

resource "aws_route_table_association" "prod-crta-public-subnet-1" {
  subnet_id      = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}


# Security group to allow SSH access and HTTP access.

resource "aws_security_group" "ssh-allowed" {
vpc_id = aws_vpc.nginx-vpc.id
egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your machines' IP. However if it is dynamic you will need to change this in the vpc every so often. 
  }
ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# SSH public key with the AWS EC2 instance.

#resource "aws_key_pair" "aws-key" {
 # key_name   = "aws-key"
  #public_key = file(var.PUBLIC_KEY_PATH)// Path is in the variables file
#}

#creating ssh-key
resource "aws_key_pair" "key-tf2" {
  key_name   = "key-tf2"
  public_key = file("${path.module}/id_rsa.pub")
}

# creatimng EC2

resource "aws_instance" "nginx_server" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
tags = {
    Name = "nginx_server"
  }
# VPC
  subnet_id = aws_subnet.prod-subnet-public-1.id
# Security Group
  vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]
# the Public SSH key
  key_name = aws_key_pair.key-tf2.id
# nginx installation
  # storing the nginx.sh file in the EC2 instnace
   provisioner "file" {
     source      = "nginx.sh"
     destination = "/tmp/nginx.sh"
  }
  # Exicuting the nginx.sh file
  # Terraform does not reccomend this method becuase Terraform state file cannot track what the scrip is provissioning
   provisioner "remote-exec" {
     inline = [
	"chmod +x /tmp/nginx.sh",
	"sudo /tmp/nginx.sh",
    ]
  }
# Setting up the ssh connection to install the nginx server
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("${var.PRIVATE_KEY_PATH}")
  }
}
