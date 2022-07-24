#Create VPC
resource "aws_vpc" "Webapp-vpc" {
  cidr_block = "10.10.0.0/16"
}

#Create Subnet (2 public and 2 Private)
resource "aws_subnet" "subnet-1a" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "${var.subnet-1a-cidr_block}"
  tags = {
    Name = "public-1a-webapp"
  }
  availability_zone = "${var.subnet-1a}"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet-2a" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "${var.subnet-2a-cidr_block}"
  tags = {
    Name = "private-2a-webapp"
  }
  availability_zone = "${var.subnet-1a}"
#   map_public_ip_on_launch = "true"  
}

resource "aws_subnet" "subnet-1b" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "${var.subnet-1b-cidr_block}"
  tags = {
    Name = "public-1b-webapp"
  }
  availability_zone = "${var.subnet-1b}"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "subnet-2b" {
  vpc_id     = aws_vpc.Webapp-vpc.id
  cidr_block = "${var.subnet-2b-cidr_block}"
  tags = {
    Name = "private-2b-webapp"
  }
  availability_zone = "${var.subnet-1b}"
}

#Create Instance
resource "aws_instance" "EC2WordPress" {
  
  ami           = var.ami
  instance_type = var.instance-type
  tags = {
    Name = "EC2 Wordpress"
  }
  subnet_id = aws_subnet.subnet-1a.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = var.key-name
}

# Internet Gateway
resource "aws_internet_gateway" "webapp-IG" {
   vpc_id = aws_vpc.Webapp-vpc.id

  tags = {
    Name = "webapp-IG"
  }
}

# Route Table for Internet Gateway
resource "aws_route_table" "public-route" {
    vpc_id = aws_vpc.Webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.webapp-IG.id
  }

  tags = {
    Name = "public_route"
  }
  
}

# Security Group
resource "aws_security_group" "allow_port80" {
  name        = "allow_port_80"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.Webapp-vpc.id

  ingress {
    description      = "allow inbound web traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   ingress {
    description      = "allow SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# Bastion Host
resource "aws_instance" "BastionHost" {
  
  ami           = "ami-024f771f651700c2c"
  instance_type = "t2.micro"
  tags = {
    Name = "bastion host"
  }
  subnet_id = aws_subnet.subnet-1b.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = var.key-name
}

# EC2 Instance
resource "aws_instance" "EC2Host"{
  ami           = "ami-0b6937ac543fe96d7"
  instance_type = "t2.micro"
  tags = {
    Name = "ec2 host"
  }
  subnet_id = aws_subnet.subnet-2b.id
  vpc_security_group_ids = [aws_security_group.allow_port80.id]
  key_name = var.key-name
}

# RDS Instance
resource "aws_db_instance" "rds-instance" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  # name                 = "mydb"
  username             = "root"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# NAT Gateway - 1
resource "aws_eip" "nat-gateway-1-eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway-1" {
  allocation_id = aws_eip.nat-gateway-1-eip.id
  subnet_id = aws_subnet.subnet-1a.id
  tags = {
    "Name" = "nat-gateway-1"
  }
}

resource "aws_route_table" "rtable1" {
  vpc_id = aws_vpc.Webapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-1.id
  }
}

resource "aws_route_table_association" "atasso1" {
  subnet_id = aws_subnet.subnet-1a.id
  route_table_id = aws_route_table.rtable1.id
}

# NAT Gateway - 2
resource "aws_eip" "nat-gateway-2-eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway-2" {
  allocation_id = aws_eip.nat-gateway-2-eip.id
  subnet_id = aws_subnet.subnet-1b.id
  tags = {
    "Name" = "nat-gateway-2"
  }
}

resource "aws_route_table" "rtable2" {
  vpc_id = aws_vpc.Webapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-2.id
  }
}

resource "aws_route_table_association" "rtasso2" {
  subnet_id = aws_subnet.subnet-1b.id
  route_table_id = aws_route_table.rtable2.id
}

resource "aws_security_group" "allow_port80_LB" {
  name        = "allow_port_80_LB"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.Webapp-vpc.id

  ingress {
    description      = "allow inbound web traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls_LB"
  }
}

resource "aws_lb" "project-lb" {
  name               = "project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_port80_LB.id]
  subnets            = [aws_subnet.subnet-1a.id, aws_subnet.subnet-1b.id]

  tags = {
    Environment = "Production"
  }
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.project-lb.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

resource "aws_lb_listener" "lb-listener22" {
  load_balancer_arn = aws_lb.project-lb.arn
  port              = "22"
  protocol          = "SSH"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

# -------------------- Target Group ----------------------------

resource "aws_lb_target_group" "target-group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Webapp-vpc.id
}

resource "aws_lb_target_group_attachment" "target-group-attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.EC2WordPress.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.BastionHost.id
  port             = 22
}