terraform {
  required_version = ">= 1.5.0"
}

variable "environment" {
  description = "Environment name echoed by the output."
  type        = string
  default     = "test"
}

output "environment" {
  description = "The configured environment name."
  value       = var.environment
}
