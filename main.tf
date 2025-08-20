# Configure aws provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Sample of remote state configuration using S3
  #   backend "s3" {
  #     bucket       = "terrafromstatefiles"
  #     key          = "Deloitte_demo.tfstate"
  #     region       = "us-east-1"
  #     profile      = "kx_demo_temp" # Change this to your AWS profile name
  #     use_lockfile = true
  #   }
}

# Sample for Terraform Cloud configuration
# terraform {

#   cloud {
#     organization = "HCP-remote-organization"

#     workspaces {
#       name    = "Dev_workspace"
#       project = "Workspace_configs"
#     }
#   }
# }


provider "aws" {
  region  = "us-east-1"
  profile = "kx_demo" # Change this to your AWS profile name
}

# Deploy a VPC 1
resource "aws_vpc" "vpc_1" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "vpc_1",
    Environment = "kx_devops_labs",
    user        = "eraki"
  }
}

# Deploy Public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "public_subnet_1",
    Environment = "kx_devops_labs",
    user        = "eraki"
  }
}

# Deploy Internet gateway
resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name        = "igw_1",
    Environment = "kx_devops_labs",
    user        = "eraki"
  }
}

# Deploy route table
resource "aws_route_table" "rt_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }

  tags = {
    Name        = "rt_1",
    Environment = "kx_devops_labs",
    user        = "eraki"
  }
}

# Route table association
resource "aws_route_table_association" "rt_ass_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.rt_1.id
}

# # Deploy ec2 in public subnet
resource "aws_instance" "ec2_1" {
  ami                         = "ami-0a3c3a20c09d6f377"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  # vpc_security_group_ids      = [aws_security_group.secgrp_1.id]

  tags = {
    Name        = "ec2_1",
    Environment = "kx_devops_labs",
    user        = "eraki"
  }
}

# # Deploy Security group of ec2_1
# resource "aws_security_group" "secgrp_1" {
#   name   = "secgrp_1"
#   vpc_id = aws_vpc.vpc_1.id

#   tags = {
#     Name        = "secgrp_1",
#     Environment = "kx_devops_labs"
#   }
# }

# Example to allow inbound traffic on port 22 in order to SSH into the instance
# Deploy ingress rules
# resource "aws_vpc_security_group_ingress_rule" "Ingress_Allow_SSH" {
#   security_group_id = aws_security_group.secgrp_1.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 22
#   to_port           = 22
#   ip_protocol       = "tcp"
# }

# # Deploy egress rules
# resource "aws_vpc_security_group_egress_rule" "Egress_Allow_all" {
#   security_group_id = aws_security_group.secgrp_1.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }
