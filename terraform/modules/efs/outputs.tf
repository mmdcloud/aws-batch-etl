output "efs_id" {
  value = aws_efs_file_system.this.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.this.dns_name
}

output "access_point_id" {
  value = aws_efs_access_point.this.id
}