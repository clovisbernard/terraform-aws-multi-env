variable "config" {
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
    sql_db = object({
      db_instance_class           = string
      engine                      = string
      username                    = string
      password                    = string
      allocated_storage           = number
      iops                        = number
      multi_az                    = bool
      publicly_accessible         = bool
      parameter_group_name        = string
      availability_zone           = string
      monitoring_interval         = number
      performance_insights_enabled= bool
      deletion_protection         = bool
      create_monitoring_role      = bool
      create_subnet_group         = bool
      create_option_group         = bool
    })
    tags = map(string)
  })
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (>=2, different AZs)."
  type        = list(string)
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}
