variable "name" {
  description = "Name tag for the EFS file system"
  type        = string
}

variable "creation_token" {
  type        = string
}

variable "encrypted" {
  type        = bool
  default     = true
}

variable "performance_mode" {
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  type        = string
  default     = "bursting"
}

variable "transition_to_ia" {
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs (one per AZ)"
  type        = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "backup_policy_status" {
  type    = string
  default = "ENABLED"
}

variable "posix_uid" {
  type    = number
  default = 50000
}

variable "posix_gid" {
  type    = number
  default = 50000
}

variable "root_path" {
  type    = string
  default = "/airflow"
}

variable "root_permissions" {
  type    = string
  default = "755"
}

variable "access_point_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}