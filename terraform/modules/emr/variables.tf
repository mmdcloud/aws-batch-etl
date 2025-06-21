variable "name" {}
variable "release_label" {}
variable "type" {}
variable "maximum_cpu" {}
variable "maximum_memory" {}
variable "subnet_ids" {}
variable "security_group_ids" {}
variable "maximum_memory" {}
variable "auto_start_enabled" {}
variable "auto_stop_enabled" {}
variable "auto_stop_idle_timeout_minutes" {}
variable "initial_capacity" {
  type = list(object({
    initial_capacity_type = string
    worker_count          = number
    worker_configuration  = object({
      cpu    = string
      memory = string
    })
  }))
}
