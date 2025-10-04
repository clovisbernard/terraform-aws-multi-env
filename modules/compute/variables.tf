variable "infra" {
  type = object({
    vpc     = object({ cidr = string })
    subnets = map(string)
    ec2     = object({
      aws_region    = string
      ami_id        = string
      instance_type = string
      key_name      = string
      subnet_name   = string
      volume_size   = number
    })
    tags = map(string)
  })
}

variable "subnet_id" {
  type = string
}
