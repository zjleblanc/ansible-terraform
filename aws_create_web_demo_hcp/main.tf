# -----------------------------------------------------------------------------
# 1. AWS networking (VPC, subnet, internet gateway, route)
# -----------------------------------------------------------------------------

data "aws_ami" "rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-8*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_vpc" "web_demo" {
  cidr_block           = var.web_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.web_tags_base, {
    Name = "web-demo-vpc"
  })
}

resource "aws_internet_gateway" "web_demo" {
  vpc_id = aws_vpc.web_demo.id
  tags   = merge(var.web_tags_base, { Name = "web-demo-igw" })
}

resource "aws_subnet" "web_demo" {
  vpc_id                  = aws_vpc.web_demo.id
  cidr_block              = var.web_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = merge(var.web_tags_base, { Name = "web-demo-subnet" })
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_route_table" "web_demo" {
  vpc_id = aws_vpc.web_demo.id
  tags   = merge(var.web_tags_base, { Name = "web-demo-rt" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_demo.id
  }
}

resource "aws_route_table_association" "web_demo" {
  subnet_id      = aws_subnet.web_demo.id
  route_table_id = aws_route_table.web_demo.id
}

# -----------------------------------------------------------------------------
# 2. Security group (SSH, HTTP, HTTPS)
# -----------------------------------------------------------------------------

resource "aws_security_group" "web_demo" {
  name        = "web-demo-sg"
  description = "SSH and web traffic for demo"
  vpc_id      = aws_vpc.web_demo.id
  tags        = merge(var.web_tags_base, { Name = "web-demo-sg" })

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# 3. SSH key pair and two web server instances
# -----------------------------------------------------------------------------

resource "aws_key_pair" "web_demo" {
  key_name   = var.web_demo_key_name
  public_key = var.web_demo_ssh_pubkey
  tags       = var.web_tags_base
}

resource "aws_instance" "web_demo" {
  count         = 2
  ami           = data.aws_ami.rhel.id
  instance_type = var.web_instance_type
  subnet_id     = aws_subnet.web_demo.id
  key_name      = aws_key_pair.web_demo.key_name

  vpc_security_group_ids = [aws_security_group.web_demo.id]
  associate_public_ip_address = true

  tags = merge(var.web_tags_base, {
    Name = "${var.web_vm_name}${count.index}"
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

# -----------------------------------------------------------------------------
# Outputs (for Ansible or AAP inventory)
# -----------------------------------------------------------------------------

output "instance_ids" {
  value       = aws_instance.web_demo[*].id
  description = "EC2 instance IDs"
}

output "public_ips" {
  value       = aws_instance.web_demo[*].public_ip
  description = "Public IPs of the web servers"
}

output "private_ips" {
  value       = aws_instance.web_demo[*].private_ip
  description = "Private IPs of the web servers"
}

output "instance_names" {
  value       = aws_instance.web_demo[*].tags_all["Name"]
  description = "Names of the web instances"
}
