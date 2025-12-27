variable "region" {
  type    = string
}

variable "db_name" {
  type    = string
}

variable "env" {
  type    = string
}

variable "vehicle-images-code-version" {
  type    = string
}

variable "public_subnets" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}

variable "domain_name" {
  type        = string
  description = "The domain name for the application"  
}