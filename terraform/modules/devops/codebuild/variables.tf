variable "cache_bucket_name" {
  description = "Name of the S3 bucket for caching"
  type        = string
  default     = ""
}

variable "role" {
  description = "Name of the IAM role for CodeBuild"
  type        = string
  default     = ""
}

variable "force_destroy_cache_bucket" {
  description = "Force destroy the S3 bucket"
  type        = bool
  default     = true
}

variable "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "codebuild_project_description" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "build_timeout" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "compute_type" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "env_image" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "env_type" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "image_pull_credentials_type" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "privileged_mode" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables for the CodeBuild project"
  type = list(object({
    name   = string
    value = string
  }))  
  default     = []
}

variable "fetch_submodules" {
  description = "Name of the CodeBuild project"
  type        = bool
  default     = false  
}

variable "source_version" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""  
}

variable "source_type" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}

variable "source_location" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}

variable "source_git_clone_depth"  {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}

variable "cloudwatch_group_name" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}
variable "cloudwatch_stream_name" {
  description = "Name of the CodeBuild project"
  type        = string
  default     = ""
}