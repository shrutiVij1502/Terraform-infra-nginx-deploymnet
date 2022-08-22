# Launch an ec2 instance from terrform and deploy nginx server in that instance.
# Show the IP of the server in the output.

# ADD-ON Task
## Create a custom VPC, subnets (public and private), route tables, and the whole network infra and launch the instance in that VPC.

## Step 1 - Launch ubuntu instance on the AWS and access via terminal

![image](https://user-images.githubusercontent.com/67600604/184825997-b372c460-7ebf-44e4-b11a-33aca6e6ad96.png)

![image](https://user-images.githubusercontent.com/67600604/184826577-b4d07f8d-9ec2-45b0-8499-ba9386dea13d.png)

## Step 2 - Install Terraform in the sever 

``` 
sudo mkdir -p /opt/terraform
cd /opt/terraform
sudo apt-get install unzip
https://www.terraform.io/downloads.html
wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
unzip terraform_1.0.7_linux_amd64.zip
----sudo mv terraform /opt/terraform-----

check it by using the command - terraform --version 

```
## Step 3 - Installing AWS cli in the server 

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## Step 4 - To create AWS user and run the command aws configure and add the "Access key" and "Secret Key" and configure the AWS shell

![image](https://user-images.githubusercontent.com/67600604/184829544-cc281cac-9e05-40f6-a353-943401ad71db.png)

## step 5 - To create the public and private key using the ssh keygen

Now, we have to create the private and public key to access our newly created instance via terraform

![image](https://user-images.githubusercontent.com/67600604/184830113-8328dac7-ef71-44dc-be81-f41adcf23191.png)

Run the Command 

```ssh-keygen```
press enter 3 times 
check in the root directory , there should be a .ssh directory formed 

now copy both the files in the /opt/terraform folder (our terraform directory)

## Step 6 - to create infra file for the creation of the terraform instance 

Now, create a file named as "instance.tf" in the /opt/terraform folder , you can get the same file in the repo 

After that, run the folowing commands to create and apply the terraform changes

```
terraform init
terraform plan
terraform apply
```

when it gets completed , go to  AWS console and check the instance created and when i hit the public ip of that instance it should be like this:

![image](https://user-images.githubusercontent.com/67600604/184831458-4481d042-7305-49ea-a26b-7d1071e23e06.png)

### Important Note - we have created a new private key for the newly created instance

now, to access the new instance using ssh , we need to go into the /opt/terraform folder in our aws server and then run the command ``` ssh -i id_rsa ec2-user@ipaddress``` 

you will be able to get access using the ssh now to your server created via terraform - 

![image](https://user-images.githubusercontent.com/67600604/184835597-a0d93298-a338-4900-8b67-55e8398beabe.png)


# ADD-ON Task

Assuming you want to run this instance in a new AWS VPC, we will create a new AWS VPC.

```
resource "aws_vpc" "nginx-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"
}
```

Create a public subnet for the VPC we created above.

```
resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id                  = aws_vpc.nginx-vpc.id // Referencing the id of the VPC from abouve code block
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" // Makes this a public subnet
  availability_zone       = "us-west-2a"
}

```

Create an Internet Gateway for the VPC. The VPC require an IGW to communicate over the internet.

```
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
}

```

Create a custom route table for the VPC.

```
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
```

for more Reference - https://awstip.com/how-to-create-an-nginx-instance-in-aws-using-terraform-feb6af12749a

Create a variables.tf file and add the following variables.

```
variable "PRIVATE_KEY_PATH" {
  default = "aws-key"
}
variable "PUBLIC_KEY_PATH" {
  default = "aws-key.pub"
}
variable "EC2_USER" {
  default = "ubuntu"
}
```
Open the terminal and run the following commands.

```
terraform init // initialise terraform
terraform fmt // format the code
terraform plan // This will show you what resources terraform will create
terraform apply // This will create all the resources in your AWS account
```

Below is the Complete file 

```
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
```
we should have these files in our folder 

![image](https://user-images.githubusercontent.com/67600604/185873748-8056fe67-9fb4-442d-ac33-1e8b3b7ca8a0.png)



Additional Note - curl http://169.254.169.254/latest/meta-data/public-ipv4
curl ifconfig.me

we can get the public ip of the instance using the command
