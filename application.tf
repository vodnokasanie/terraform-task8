provider "aws" {
  region = "us-east-1"
}

# Data sources for existing resources
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["cmtr-ghjc0xhd-vpc"]
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "cidr-block"
    values = ["10.0.1.0/24"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "public_b" {
  filter {
    name   = "cidr-block"
    values = ["10.0.3.0/24"]
  }
  vpc_id = data.aws_vpc.selected.id
}

data "aws_security_group" "ec2_sg" {
  filter {
    name   = "group-name"
    values = ["cmtr-ghjc0xhd-ec2_sg"]
  }
}

data "aws_security_group" "http_sg" {
  filter {
    name   = "group-name"
    values = ["cmtr-ghjc0xhd-http_sg"]
  }
}

data "aws_security_group" "lb_sg" {
  filter {
    name   = "group-name"
    values = ["cmtr-ghjc0xhd-sglb"]
  }
}

data "aws_iam_instance_profile" "instance_profile" {
  name = "cmtr-ghjc0xhd-instance_profile"
}

#######################
# Launch Template
#######################

resource "aws_launch_template" "this" {
  name_prefix   = "cmtr-ghjc0xhd-template"
  image_id      = "ami-09e6f87a47903347c"
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name

  iam_instance_profile {
    name = data.aws_iam_instance_profile.instance_profile.name
  }

  network_interfaces {
    security_groups       = [data.aws_security_group.ec2_sg.id, data.aws_security_group.http_sg.id]
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y aws-cli httpd jq
    systemctl enable httpd
    systemctl start httpd

    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

    echo "This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Terraform = "true"
      Project   = "cmtr-ghjc0xhd"
    }
  }

  tags = {
    Terraform = "true"
    Project   = "cmtr-ghjc0xhd"
  }
}

#######################
# Auto Scaling Group
#######################

resource "aws_autoscaling_group" "this" {
  name                = "cmtr-ghjc0xhd-asg"
  max_size            = 2
  min_size            = 1
  desired_capacity    = 2
  vpc_zone_identifier = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns,
    ]
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "cmtr-ghjc0xhd"
    propagate_at_launch = true
  }
}

#######################
# Application Load Balancer
#######################

resource "aws_lb" "this" {
  name               = "cmtr-ghjc0xhd-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_sg.id]
  subnets            = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]

  tags = {
    Terraform = "true"
    Project   = "cmtr-ghjc0xhd"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "cmtr-ghjc0xhd-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Terraform = "true"
    Project   = "cmtr-ghjc0xhd"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}
