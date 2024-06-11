variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "vpc_cidr range"
}

variable "subnet1_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "subnet1_cidr range"
}

variable "subnet2_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "subnet2_cidr range"
}

variable "route_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "vpc_cidr range"
}

