resource "aws_instance" "example" {
  ami           = var.infra.ec2.ami_id
  instance_type = var.infra.ec2.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.infra.ec2.key_name

  root_block_device {
    volume_size = var.infra.ec2.volume_size
  }

  tags = merge(var.infra.tags, {
    Name = "${var.infra.tags["environment"]}-${var.infra.tags["project"]}-compute"
  })
}
