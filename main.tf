##########################
# Implementing Highly Available Web-Server in any Region Default VPC
# Create:
#   -Security Group for Web Server 
#   -Launch Configuration with Auto AMI Lookup
#   -Auto Scaling Group using 2 Availability Zones
#   -Classic Load Balancer in 2 Avalability Zones
#
#
# All the best 12/2023
# Zheni Ekoebve
# HIRE ME!




provider "aws" {
    region = "us-east-1"    
}


data "aws_availability_zones" "available"{}
data "aws_ami" "latest_amazon" {
    owners = ["137112412989"]
    most_recent = true
    filter {
        name = "name"
        values = ["al2023-ami-2023.2.20231113.0-kernel-6.1-*"]
    }
}

######################


resource "aws_security_group" "web" {
    name = "Dynamic Security Group for the Web-server"

    dynamic "ingress" {
        for_each = ["80", "443"]
        content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }
    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name  = "DSG"
        Owner = "Zheni Ekoebve"
    }
}


resource "aws_launch_configuration" "web" {
    associate_public_ip_address = true
    // name            = "WebServer-Highly-Available-LC"
    name_prefix     = "WebServer-Highly-Available-LC"
    image_id        = data.aws_ami.latest_amazon.id
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.web.id]
    user_data = file("user_data.sh")

  lifecycle{
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "web" {
    name              = "ASG-${aws_launch_configuration.web.name}"
    launch_configuration  = aws_launch_configuration.web.name
    min_size              = 2
    max_size              = 2
    min_elb_capacity      = 2
    vpc_zone_identifier   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id] 
    health_check_type     = "ELB"
    load_balancers        = [aws_elb.web.name]

  dynamic "tag" {
    for_each = {
        Name = "WebServer in ASG"
        Owner = "Zheni Ekoebve"
        TAGKEY = "TAGVALUE"
    }
    content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
  }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "web" {
    name                    = "WebServer-HA-ELB"
    availability_zones      = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
    security_groups          = [aws_security_group.web.id]
    listener {
        lb_port             = 80
        lb_protocol         = "http"
        instance_port       = 80
        instance_protocol   = "http"
    }
    health_check {
        healthy_treshold   = 2
        unhealthy_treshold = 2
        timeout             = 3
        target              = "HTTP:80/"
        interval            = 10
    }
    tags = {
        Name = "WebServer-Highly-Available-ELB"
    }
}

resource "aws_default_subnet" "default_az1" {
    availability_zone = data.aws_availability_zones.available.names[0]
}
resource "aws_default_subnet" "default_az2" {
    availability_zone = data.aws_availability_zones.available.names[1]
}





#----------------------------------------
output "web_loadbalancer_url" {
    value = aws_elb.web.dns_name
}
