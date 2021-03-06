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
  instance_type         = var.server_instance_type
  block_device_mappings = var.server_storage
  enable_ccm            = var.enable_ccm
  controlplane_internal = var.controlplane_internal
  servers               = var.servers
}

module "agents" {
  source  = "git::https://github.com/rancherfederal/rke2-aws-tf.git//modules/agent-nodepool"
  name                        = "generic"
  vpc_id                      = data.aws_vpc.default.id
  subnets                     = [data.aws_subnet.default.id]
  ami                         = var.ami
  ssh_authorized_keys         = [tls_private_key.ssh.public_key_openssh]
  tags                        = var.tags
  asg                         = var.asg
  instance_type               = var.agent_instance_type
  block_device_mappings       = var.agent_storage
  # extra_block_device_mappings = [ var.agent_storage_extra ] 
  pre_userdata                = var.agent_pre_userdata
  cluster_data                = module.rke2.cluster_data
  enable_ccm                  = var.enable_ccm
  enable_autoscaler           = var.enable_autoscaler
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

resource "null_resource" "k8s_additions" {
  depends_on = [null_resource.kubeconfig]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOT
      export KUBECONFIG=rke2.yaml
      kubectl patch psp system-unrestricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
      kubectl patch psp global-unrestricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
      kubectl patch psp global-restricted-psp  -p '{"metadata": {"annotations":{"seccomp.security.alpha.kubernetes.io/allowedProfileNames": "*"}}}'
      kubectl apply -f dependencies/aws/ebs-sc.yaml
    EOT
  }
}