variable "env" {
  description = "Environment to deploy (dev|prod)."
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be one of: dev, prod."
  }
}
