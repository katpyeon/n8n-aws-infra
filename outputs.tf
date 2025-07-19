output "alb_dns" {
  value = aws_lb.alb.dns_name
}
output "fqdn" {
  value = local.fqdn
}
output "health_check_url" {
  value       = "https://${local.fqdn}/healthz"
  description = "n8n 헬스체크 URL"
}
output "n8n_url" {
  value       = "https://${local.fqdn}"
  description = "n8n 접속 URL"
}