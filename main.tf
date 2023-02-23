provider "aws" {
region = "us-west-2"
}

variable "vpc-cidr-block1" {
}

variable "subnet-cidr-block11" {

}
resource "aws_vpc" "alex-vpc" {
    cidr_block = var.vpc-cidr-block1

     enable_dns_hostnames = "true"
     
    tags = {
        Name = "Alex VPC"
    }
}

resource "aws_subnet" "public-subnet-alex" {
  vpc_id     = aws_vpc.alex-vpc.id
  cidr_block = var.subnet-cidr-block11
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public alex sub"
  }
}

resource "aws_internet_gateway" "inter-gateway" {
  vpc_id = aws_vpc.alex-vpc.id

  tags = {
    Name = "Internet Gateway Alex"
  }
}
resource "aws_route_table_association" "rt-alex" {
  subnet_id      = aws_subnet.public-subnet-alex.id
  route_table_id = aws_route_table.alex-route-table.id
}

resource "aws_route_table" "alex-route-table" {
  vpc_id = aws_vpc.alex-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inter-gateway.id
  }

  tags = {
    Name = "public Alex Route Table"
  }
}


resource "aws_instance" "Master-node" {
  ami = "ami-0ceecbb0f30a902a6"
  instance_type = "t3.small"
  associate_public_ip_address = true
  subnet_id      = aws_subnet.public-subnet-alex.id
  count = 1
  vpc_security_group_ids = [aws_security_group.alex_tls.id]
  key_name = "vockey"
    
  user_data = <<EOF
  	#! /bin/bash
	sudo yum update -y
 	sudo yum install docker -y
 	sudo yum install git -y
 	sudo groupadd docker
 	sudo usermod -aG docker $USER
 	newgrp docker
 	sudo service docker start
 	sudo systemctl start docker
 	sudo chmod 666 /var/run/docker.sock
 	sudo systemctl enable docker
 	sudo hostnamectl set-hostname Master-Manager
 	EOF
 	
  tags = {
    Name = "Master-Manager"
  }

}




resource "aws_security_group" "alex_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.alex-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

