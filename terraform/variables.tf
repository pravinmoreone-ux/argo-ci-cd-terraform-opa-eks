variable "aws_region" {
  description = "AWS region where infrastructure will be created"
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = contains(["ap-south-1"], var.aws_region)
    error_message = "Only ap-south-1 is allowed for this lab."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "node_instance_type" {
  description = "EKS worker node EC2 instance type"
  type        = string
  default     = "t3.small"

  validation {
    condition = contains([
      "t3.small",
      "t3.medium"
    ], var.node_instance_type)

    error_message = "Only t3.small and t3.medium are allowed for EKS worker nodes."
  }
}
