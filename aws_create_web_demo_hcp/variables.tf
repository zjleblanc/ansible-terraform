# -----------------------------------------------------------------------------
# AWS provider authentication (for TFE workspace aws-web-demo-dev)
# Set in TFE as sensitive where applicable.
# -----------------------------------------------------------------------------
variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID for API authentication"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key for API authentication"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Generic AWS vars
# -----------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for resources"
}

variable "web_tags_base" {
  type = map(string)
  default = {
    owner      = "zleblanc"
    demo       = "web"
    deployment = "terraform"
    config     = "ansible"
  }
}

# -----------------------------------------------------------------------------
# Web demo AWS vars
# -----------------------------------------------------------------------------
variable "web_vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for the demo VPC"
}

variable "web_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR for the public subnet"
}

variable "web_vm_name" {
  type        = string
  default     = "web-demo-vm"
  description = "Base name for web EC2 instances"
}

variable "web_instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type for web servers"
}

variable "web_demo_admin_username" {
  type        = string
  default     = "ec2-user"
  description = "SSH username (e.g. ec2-user for Amazon Linux, ec2-user for RHEL on AWS)"
}

variable "web_demo_key_name" {
  type        = string
  default     = "web-demo-key"
  description = "Name for the SSH key pair created in AWS"
}

variable "web_demo_ssh_pubkey" {
  type        = string
  description = "Contents of the SSH public key for instance access"
}
