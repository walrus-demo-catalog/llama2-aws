output "endpoint_service_url" {
  description = "URL to access the web UI"
  value = "http://${aws_spot_instance_request.llama.public_ip}:7860"
}
