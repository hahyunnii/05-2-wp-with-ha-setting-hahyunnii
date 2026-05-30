variable "aws_region" {
  description = "AWS region for this lab"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used in AWS resource names"
  type        = string
  default     = "ccaws-tf04"
}

variable "instance_type" {
  description = "EC2 instance type for the WordPress web server"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class — keep db.t3.micro to conserve Academy credits"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "MySQL database name for WordPress"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "MySQL master username"
  type        = string
  default     = "wpadmin"
}

variable "db_master_password" {
  description = "MySQL master password — supply via TF_VAR_db_master_password env var, never in tfvars"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH troubleshooting (leave empty to skip)"
  type        = string
  default     = ""
}
