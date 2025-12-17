output "airflow_webserver_url" {
  description = "The URL of the Airflow webserver"
  value       = module.airflow_lb.lb_dns_name
}