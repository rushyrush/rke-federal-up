provider "aws" {
  region = var.aws_region
}

# Query for defaults
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = "${var.aws_region}a"
  default_for_az    = true
}

# Private Key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pem" {
  filename        = "${var.cluster_name}.pem"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

module "rke2" {
  source = "git::https://github.com/rancherfederal/rke2-aws-tf.git"
  cluster_name          = var.cluster_name
  vpc_id                = data.aws_vpc.default.id
  subnets               = [data.aws_subnet.default.id]
  ami                   = var.ami
  ssh_authorized_keys   = [tls_private_key.ssh.public_key_openssh]
  tags                  = var.tags
  controlplane_internal = false # Note this defaults to best practice of true, but is explicitly set to public for demo purposes
  instance_type         = var.server_instance_type
  block_device_mappings = var.server_storage
}

module "agents" {
  source = "git::https://github.com/rancherfederal/rke2-aws-tf.git//modules/agent-nodepool"
  name                   = "generic"
  vpc_id                 = data.aws_vpc.default.id
  subnets                = [data.aws_subnet.default.id]
  ami                    = var.ami
  ssh_authorized_keys    = [tls_private_key.ssh.public_key_openssh]
  tags                   = var.tags
  asg                    = var.asg
  instance_type          = var.agent_instance_type
  block_device_mappings  = var.agent_storage
  block_device_mappings2  = var.agent_storage2
  cluster_data           = module.rke2.cluster_data
}

resource "aws_security_group_rule" "rke2_ssh" {
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = module.rke2.cluster_data.cluster_sg
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Generic outputs as examples
output "rke2" {
  value = module.rke2
}

resource "null_resource" "kubeconfig" {
  depends_on = [module.rke2]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "aws s3 cp ${module.rke2.kubeconfig_path} rke2.yaml"
  }
}

resource "aws_launch_template" "this" {
  name                   = "${var.name}-rke2-nodepool"
  image_id               = var.ami
  instance_type          = var.instance_type
  user_data              = var.userdata
  vpc_security_group_ids = concat([aws_security_group.this.id], var.vpc_security_group_ids)

  block_device_mappings {
    {
    device_name = lookup(var.block_device_mappings, "device_name", "/dev/sda1")
      ebs {
        volume_type           = lookup(var.block_device_mappings, "type", null)
        volume_size           = lookup(var.block_device_mappings, "size", null)
        iops                  = lookup(var.block_device_mappings, "iops", null)
        kms_key_id            = lookup(var.block_device_mappings, "kms_key_id", null)
        encrypted             = lookup(var.block_device_mappings, "encrypted", null)
        delete_on_termination = lookup(var.block_device_mappings, "delete_on_termination", null)
      }
    },  
    {
    device_name = lookup(var.block_device_mappings, "device_name", "/dev/sdb1")  
      ebs {
        volume_type           = lookup(var.block_device_mappings2, "type", null)
        volume_size           = lookup(var.block_device_mappings2, "size", null)
        iops                  = lookup(var.block_device_mappings, "iops", null)
        kms_key_id            = lookup(var.block_device_mappings, "kms_key_id", null)
        encrypted             = lookup(var.block_device_mappings, "encrypted", null)
        delete_on_termination = lookup(var.block_device_mappings, "delete_on_termination", null)
      }
    }  
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  tags = merge({}, var.tags)
}