variable "aws_region" {
  default = "us-gov-west-1" # update ami if changed
}

variable "cluster_name" {
  default = "rke2"
}

# server config
variable "servers" {
  default = 1
}

variable "server_instance_type" {
  default = "m5a.large"
}

variable "server_storage" {
  default = {
    "size" = 30
    type   = "gp2"
  }
}

# agent config
variable "agent_instance_type" {
  default = "m5a.large"
}

variable "asg" {
  default = { min : 3, max : 5, desired : 3 } # agent count
}

variable "agent_storage" {
  default = {
    "size" = 30
    type   = "gp2"
  }
}

variable "enable_autoscaler" {
  default = false
}

variable "agent_spot" {
  default = false
}

variable "ami" {
  default = "ami-84556de5" # ubuntu 20.04
}

variable "tags" {
  default = {
    "terraform" = "true",
    "env"       = "rke2",
  }
}

variable "agent_pre_userdata" {
  description = "Custom userdata to run immediately before rke2 node attempts to join cluster, after required rke2, dependencies are installed"
  type        = string
  default     = <<EOF
# Configure aws cli default region to current region
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Tune vm sysctl for elasticsearch
sysctl -w vm.max_map_count=524288
echo 'vm.max_map_count=262144' > /etc/sysctl.d/vm-max_map_count.conf

# longhorn RWX nfs req
apt install nfs-common -y

# SonarQube host pre-requisites
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

# Preload kernel modules required by istio-init, required for selinux enforcing instances using istio-init
modprobe xt_REDIRECT
modprobe xt_owner
modprobe xt_statistic
# Persist modules after reboots
printf "xt_REDIRECT\nxt_owner\nxt_statistic\n" | sudo tee -a /etc/modules
EOF
}

variable "controlplane_internal" {
  default = true
}

variable "enable_ccm" {
  default = true
}

