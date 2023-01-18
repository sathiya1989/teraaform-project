terraform {
  backend "s3" {
    bucket = "terraform-project-demo-bucket-2023"
    key    = "dev/terraform-state"
    region = "ap-south-1"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "cardapp-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "cardapp-vpc"
  }
}

resource "aws_subnet" "cardapp-subnet-public-1a" {
  vpc_id     = aws_vpc.cardapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "cardapp-subnet-public-1a"
  }
}

resource "aws_subnet" "cardapp-subnet-private-1b" {
  vpc_id     = aws_vpc.cardapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "cardapp-subnet-private-1b"
  }
}

resource "aws_subnet" "cardapp-subnet-public-1c" {
  vpc_id     = aws_vpc.cardapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "cardapp-subnet-public-1c"
  }
}

resource "aws_subnet" "cardapp-subnet-private-1d" {
  vpc_id     = aws_vpc.cardapp-vpc.id
  cidr_block = "10.10.3.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "cardapp-subnet-private-1d"
  }
}

#creating sercutity group

resource "aws_security_group" "allow_all" {
  name        = "allow_port-all"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.cardapp-vpc.id

  ingress {
    description      = "http t0affic"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

#creating internet gateway for vpc

resource "aws_internet_gateway" "cardapp-vpc-IG" {
  vpc_id = aws_vpc.cardapp-vpc.id
  tags = {
    Name = "cardapp-vpc-IG"
  }
}

#creating route table for vpc

resource "aws_route_table" "cardapp-public-RT" {
  vpc_id = aws_vpc.cardapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cardapp-vpc-IG.id
  }

  
  tags = {
    Name = "cardapp-public-RT"
  }
}

resource "aws_route_table_association" "cardapp-public-RT-association-1a" {
  subnet_id      = aws_subnet.cardapp-subnet-public-1a.id
  route_table_id = aws_route_table.cardapp-public-RT.id
}

resource "aws_route_table_association" "cardapp-public-RT-association-1c" {
  subnet_id      = aws_subnet.cardapp-subnet-public-1c.id
  route_table_id = aws_route_table.cardapp-public-RT.id
}

#creating load balancer

resource "aws_lb" "cardapp-loadbalancer-public" {
  name               = "cardapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            = [aws_subnet.cardapp-subnet-public-1a.id,aws_subnet.cardapp-subnet-public-1c.id]

  enable_deletion_protection = false


  tags = {
    Environment = "development"
  }
}


#creating an instances

resource "aws_instance" "cardapp-1" {
  ami           = "ami-0f69bc5520884278e"
  key_name      = "chennai-first-instance"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cardapp-subnet-public-1a.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = filebase64("cardapp.sh")
  tags = {
    Name            = "cardapp-1"
    App             = "frontend"
    
  }

}

resource "aws_instance" "cardapp-2" {
  ami           = "ami-0f69bc5520884278e"
  key_name      = "chennai-first-instance"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cardapp-subnet-private-1b.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  tags = {
    Name            = "cardapp-2"
    App             = "frontend"
    
  }

}

resource "aws_instance" "cardapp-3" {
  ami           = "ami-0f69bc5520884278e"
  key_name      = "chennai-first-instance"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cardapp-subnet-public-1c.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = filebase64("cardapp.sh")
  tags = {
    Name            = "cardapp-3"
    App             = "frontend"
    
  }

}

resource "aws_instance" "cardapp-4" {
  ami           = "ami-0f69bc5520884278e"
  key_name      = "chennai-first-instance"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.cardapp-subnet-private-1d.id
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  tags = {
    Name            = "cardapp-4"
    App             = "frontend"
    
  }

}

resource "aws_lb_target_group" "cardapp-target-group" {
  name     = "cardapp-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cardapp-vpc.id
}

resource "aws_lb_target_group_attachment" "cardapp-lb-target-group-attachment-1" {
  target_group_arn = aws_lb_target_group.cardapp-target-group.arn
  target_id        = aws_instance.cardapp-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "cardapp-lb-target-group-attachment-2" {
  target_group_arn = aws_lb_target_group.cardapp-target-group.arn
  target_id        = aws_instance.cardapp-3.id
  port             = 80
}

resource "aws_lb_listener" "cardapp-lb-listner" {
  load_balancer_arn = aws_lb.cardapp-loadbalancer-public.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cardapp-target-group.arn
  }
}
