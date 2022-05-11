terraform1 {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc-mumbai"
  }
}
resource "aws_subnet" "pub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pub-mumbai"
  }
}
resource "aws_subnet" "pri" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pri-mumbai"
  }
}
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw-mumbai"
  }
}
resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = {
    Name = "pub-rt mumbai"
  }
}
resource "aws_route_table_association" "pubasso" {
  subnet_id      = aws_subnet.pub.id
  route_table_id = aws_route_table.pub-rt.id
}
resource "aws_eip" "myeip" {
  vpc      = true
}
resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pub.id

  tags = {
    Name = "NAT-mumbai"
  }

  
}
resource "aws_route_table" "pvt-rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }
  tags = {
    Name = "pvt-rt mumbai"
  }
}
resource "aws_route_table_association" "pvtasso" {
  subnet_id      = aws_subnet.pri.id
  route_table_id = aws_route_table.pvt-rt.id
}

resource "aws_security_group" "publicSG" {
  name        = "publicSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public"
  }
}
resource "aws_security_group" "privateSG" {
  name        = "privateSG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.publicSG.id]
    
    }
  


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private"
  }
}
  
resource "aws_instance" "public" {
  ami           = " ami-0a7b049697326f626"
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.pub.id
  associate_public_ip_address = true
  vpc_security_group_ids      =  ["${aws_security_group.publicSG.id}"]
  key_name   = "devolper"  
}
resource "aws_instance" "private" {
  ami           = " ami-0a7b049697326f626"
  instance_type = "t2.micro"
  subnet_id   = aws_subnet.pri.id
  vpc_security_group_ids      =  ["${aws_security_group.privateSG.id}"]
  key_name   = "devolper"
}
