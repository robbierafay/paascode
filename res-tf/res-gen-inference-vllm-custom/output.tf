output "api_key" {
  value       = random_uuid.api_key.result
  description = "The randomly generated API key for vLLM."
}

output "host_name" {
  value       = var.host_name
  description = "The hostname to use for the VLLM service (e.g., vllm.example.com)."
}
output "served_model_name" {
  value       = var.served_model_name
  description = "The served model name for VLLM."
  
}
