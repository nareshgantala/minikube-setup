resource "aws_vpc" "minikube_vpc" {
  cidr_block = var.cidr_block
    tags = {
    Name = "minikube_vpc"
  }
}

resource "aws_subnet" "minikube_subnet" {
  vpc_id     = aws_vpc.minikube_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "minikube_subnet"
  }
}

resource "aws_security_group" "minikube" {
  vpc_id = aws_vpc.minikube_vpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "minikube_sg"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.minikube_vpc.id

  tags = {
    Name = "minikube_gw"
  }
}

resource "aws_route_table" "minikube" {
  vpc_id = aws_vpc.minikube_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "minikube_route"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.minikube_subnet.id
  route_table_id = aws_route_table.minikube.id
}

resource "aws_instance" "minikube" {
  ami           = "ami-0b6c6ebed2801a5cb"
  subnet_id = aws_subnet.minikube_subnet.id
  associate_public_ip_address = true
  user_data_replace_on_change = true
  user_data = file("user_data.sh")
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.minikube.id]
  tags = {
    Name = "minikube"
  }
  root_block_device {
    volume_size = 30                # Size in GiB
    volume_type = "gp3"             # General Purpose SSD
    delete_on_termination = true    # Volume is deleted when the instance terminates
    encrypted = true                # Encrypt the volume
  }
}