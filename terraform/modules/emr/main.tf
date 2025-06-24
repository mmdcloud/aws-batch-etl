resource "aws_emrserverless_application" "prod_spark_app" {
  name          = var.name
  release_label = var.release_label
  type          = var.type
  dynamic "initial_capacity" {
    for_each = var.initial_capacity
    content {
      initial_capacity_type = initial_capacity.value.initial_capacity_type
      initial_capacity_config {
        worker_count = initial_capacity.value.worker_count
        worker_configuration {
          cpu    = initial_capacity.value.worker_configuration.cpu
          memory = initial_capacity.value.worker_configuration.memory
        }
      }
    }
  }

  maximum_capacity {
    cpu    = var.maximum_cpu
    memory = var.maximum_memory
  }

  network_configuration {
    subnet_ids = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  auto_start_configuration {
    enabled = var.auto_start_enabled
  }

  auto_stop_configuration {
    enabled              = var.auto_stop_enabled
    idle_timeout_minutes = var.auto_stop_idle_timeout_minutes
  }

  tags = {
    Name = var.name
  }
}
