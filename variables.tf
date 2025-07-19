variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "profile" {
  description = "AWS profile name"
  type        = string
  default     = "terraform-user"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for n8n"
  type        = string
  default     = "n8n"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "n8n_auth_password" {
  description = "n8n basic auth password"
  type        = string
  sensitive   = true
}

variable "n8n_port" {
  description = "n8n port"
  type        = number
  default     = 5678
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}