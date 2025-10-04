variable "infra" {
  type = object({
    vpc        = object({ cidr = string })
    subnets    = map(string)
    tags       = map(string)
    aws_region = string
  })
}
