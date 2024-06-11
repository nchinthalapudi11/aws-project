resource "aws_vpc" "vpc1" {
  cidr_block = var.vpc_cidr
}
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.route_cidr
    gateway_id = aws_internet_gateway.igw1.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_security_group" "sg1" {
  name   = "sg1"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    description = "allow http"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow ssh"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2-1" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id              = aws_subnet.subnet1.id
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_instance" "ec2-2" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id              = aws_subnet.subnet2.id
  user_data              = base64encode(file("userdata1.sh"))
}

resource "aws_lb" "lb1" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg1.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  tags = {
    Environment = "application"
  }
}

resource "aws_lb_target_group" "tg1" {
  name     = "tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "tga" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.ec2-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tgb" {
  target_group_arn = aws_lb_target_group.tg1.arn
  target_id        = aws_instance.ec2-2.id
  port             = 80
}
resource "aws_lb_listener" "lis" {
  load_balancer_arn = aws_lb.lb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg1.arn
  }
}


output "loadbalancerdns" {
  value = aws_lb.lb1.dns_name
}

output "ec2-1-public_ip" {
  value = aws_instance.ec2-1.public_ip
}
output "ec2-2-public_ip" {
  value = aws_instance.ec2-2.public_ip
}