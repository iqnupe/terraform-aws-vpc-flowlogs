variable "vpc_id" {
  description = "VPC ID"
  default     = ""
}

variable "tags" {
  description = "Tags To Apply To Created Resources"
  default     = {}
}

variable "s3" {
  type = object(
    {
      bucket = string
      prefix = string
      lifecycle = object(
        {
          transition_days = number
          expiration_days = number
      })
      tags = map(string)
  })
  description = "S3 configuration"
  default = {
    bucket = ""
    prefix = null
    lifecycle = {
      transition_days = 30
      expiration_days = 60
    }
    tags = {}
  }
  validation {
    condition     = var.s3.lifecycle.expiration_days > var.s3.lifecycle.transition_days
    error_message = "The lifecycle expiration days must be greater than the transition days."
  }
}
