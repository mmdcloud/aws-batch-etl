resource "aws_launch_template" "template" {
  name          = var.name
  description   = var.description
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  ebs_optimized = var.ebs_optimized
  iam_instance_profile {
    name = var.instance_profile_name
  }
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_public_ip_address = network_interfaces.value["associate_public_ip_address"]
      security_groups             = network_interfaces.value["security_groups"]
    }
  }
  user_data = var.user_data
}
