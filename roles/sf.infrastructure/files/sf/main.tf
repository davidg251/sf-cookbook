# Variables
variable "region" {
    type = string
    default = "us-east-2"
}

variable "instance_type" {
    type = string
    default = "t3.micro"
}

variable "key" {
    type = string
}

variable "ami_name" {
    type = string
}

variable "ami_owner" {
    type = string
}

provider "aws" {
  region = var.region
}


# Lookups

data "aws_ami" "jenkins" {
  most_recent      = true
  owners           = [var.ami_owner]

  filter {
    name   = "name"
    values = ["${var.ami_name}*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Resources

resource "aws_security_group" "allow_internet_http" {
  name        = "allow_internet_http"
  description = "Allow HTTPS inbound traffic from internet"

  ingress {
    description = "HTTP from internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_internet_http"
  }
}

resource "aws_efs_file_system" "jenkins-efs" {
  creation_token = "jenkins-efs"
  tags = {
    Name = "jenkins-efs"
  }
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.jenkins-efs.id
  subnet_id      = aws_instance.jenkins_ec2.subnet_id
  security_groups = [ aws_security_group.allow_internet_http.id ]
  
  depends_on = [ aws_security_group.allow_internet_http ]
}

resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins_ec2_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_policy" {
    name = "jenkins_policy"
    role = aws_iam_role.jenkins_ec2_role.name
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:*",
                "ec2:*",
                "ecr:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "jenkins_ec2_profile" {
  name = "jenkins_ec2_profile"
  role = aws_iam_role.jenkins_ec2_role.name
}

resource "aws_instance" "jenkins_ec2" {
    ami                  = data.aws_ami.jenkins.id
    instance_type        = var.instance_type
    key_name             = var.key
    security_groups      = [ aws_security_group.allow_internet_http.name ]
    tags = {
        Name = "Jenkins"
    }
    user_data_base64     = filebase64("${path.module}/scripts/attachefs.sh")
    iam_instance_profile = aws_iam_instance_profile.jenkins_ec2_profile.name
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_ec2.id
}

resource "aws_ecr_repository" "sf_repository" {
  name = "demoback"
}
