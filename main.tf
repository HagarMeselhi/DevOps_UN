provider "aws" {
region = "us-west-2"
}

variable "vpc-cidr-block" {
}

variable "subnet-cidr-block1" {

}
resource "aws_vpc" "my-vpc1" {
    cidr_block = var.vpc-cidr-block

     enable_dns_hostnames = "true"
     
    tags = {
        Name = "my 1st VPC"
    }
}

resource "aws_subnet" "public-subnet-cairo" {
  vpc_id     = aws_vpc.my-vpc1.id
  cidr_block = var.subnet-cidr-block1
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public cairo sub"
  }
}

resource "aws_internet_gateway" "inter-gw" {
  vpc_id = aws_vpc.my-vpc1.id

  tags = {
    Name = "Internet Gateway Cairo"
  }
}
resource "aws_route_table_association" "rt-cairo" {
  subnet_id      = aws_subnet.public-subnet-cairo.id
  route_table_id = aws_route_table.cairo-route-table.id
}

resource "aws_route_table" "cairo-route-table" {
  vpc_id = aws_vpc.cairo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inter-gw.id
  }

  tags = {
    Name = "public Cairo Route Table"
  }
}


resource "aws_instance" "Master-node" {
  ami = "ami-0ceecbb0f30a902a6"
  instance_type = "t3.small"
  associate_public_ip_address = true
  subnet_id      = aws_subnet.public-subnet-cairo.id
  count = 1
  vpc_security_group_ids = [aws_security_group.cairo_tls.id]
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




resource "aws_security_group" "cairo_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cairo-vpc.id

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

