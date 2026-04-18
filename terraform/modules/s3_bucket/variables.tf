variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "bucket_suffix" {
  description = "Suffix to destinguish multiple buckets within the same environment"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}