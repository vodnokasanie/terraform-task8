variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_id" {
  description = "Project identifier used for tagging all resources"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the instances will be launched"
  type        = list(string)
}

variable "security_group_ec2" {
  description = "Security group ID that allows SSH access to EC2 instances"
  type        = string
}

variable "security_group_http" {
  description = "Security group ID that allows HTTP access to EC2 instances"
  type        = string
}

variable "security_group_lb" {
  description = "Security group ID that allows HTTP access to the Load Balancer"
  type        = string
}

variable "instance_profile" {
  description = "IAM Instance Profile name for EC2 instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for launching EC2 instances"
  type        = string
  default     = "ami-09e6f87a47903347c"
}
