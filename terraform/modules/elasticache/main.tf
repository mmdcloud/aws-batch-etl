# resource "aws_elasticache_cluster" "cluster" {
#   cluster_id           = var.cluster_id
#   engine               = var.cluster_engine
#   node_type            = var.node_type
#   num_cache_nodes      = var.num_cache_nodes
#   parameter_group_name = var.parameter_group_name
#   engine_version       = var.engine_version
#   port                 = var.port
#   maintenance_window   = var.maintenance_window
# }

resource "aws_elasticache_replication_group" "replication_group" {
  description                = var.description
  replication_group_id       = var.replication_group_id
  port                       = var.port
  maintenance_window         = var.maintenance_window
  engine                     = var.engine
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.automatic_failover_enabled
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group_name.name
  security_group_ids         = [aws_security_group.redis_sg.id]
  parameter_group_name       = var.parameter_group_name
  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configuration
    content {
      log_type         = log_delivery_configuration.value.log_type
      log_format       = log_delivery_configuration.value.log_format
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
    }
  }
  tags = {
    Name = var.replication_group_id
  }
}

resource "aws_elasticache_subnet_group" "subnet_group_name" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_group_ids
  tags = {
    Name = var.subnet_group_name
  }
}