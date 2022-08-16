#creating instance
resource "aws_instance" "web" {
  ami                    = "ami-04893cdb768d0f9ee"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key-tf1.key_name
  vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"]
  tags = {
    Name = "first-tf-instance"
  }
  user_data = <<EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo service nginx start
sudo echo "Hii Shruti" >/usr/share/nginx/html/index.html
EOF
}
#creating ssh-key
resource "aws_key_pair" "key-tf1" {
  key_name   = "key-tf1"
  public_key = file("${path.module}/id_rsa.pub")
}
#creating security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  dynamic "ingress" {
    for_each = [22, 80, 443]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
