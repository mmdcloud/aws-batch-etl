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
#   initial_capacity {
#     initial_capacity_type = "Driver"

#     initial_capacity_config {
#       worker_count = 1
#       worker_configuration {
#         cpu    = "4 vCPU"
#         memory = "16 GB"
#       }
#     }
#   }

#   initial_capacity {
#     initial_capacity_type = "Executor"

#     initial_capacity_config {
#       worker_count = 5
#       worker_configuration {
#         cpu    = "8 vCPU"
#         memory = "32 GB"
#       }
#     }
#   }

  maximum_capacity {
    cpu    = "100 vCPU"
    memory = "500 GB"
  }

  network_configuration {
    subnet_ids = var.subnet_ids
    security_group_ids = [
      aws_security_group.emr_serverless_sg.id
    ]
  }

  auto_start_configuration {
    enabled = true
  }

  auto_stop_configuration {
    enabled   = true
    idle_timeout_minutes = 30
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}