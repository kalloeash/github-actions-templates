# Fixture for the terraform-plan and terraform-apply self-tests. terraform_data is a
# built-in resource, so plan and apply run with the local backend, no provider download,
# no cloud, and no credentials. The Azure paths of both blocks cannot run against a
# fixture and are proven by a consumer; see the testing section in docs/architecture.md.
terraform {
  required_version = ">= 1.5.0"
}

variable "environment" {
  description = "Value stored by the fixture resource."
  type        = string
  default     = "test"
}

resource "terraform_data" "fixture" {
  input = var.environment
}

output "environment" {
  description = "The stored value, read back after apply."
  value       = terraform_data.fixture.output
}
