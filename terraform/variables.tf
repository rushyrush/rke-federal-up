
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
  default = "m5.large"
}

variable "server_storage" {
  default = {
    "size" = 30
    type   = "gp2"
  }
}
# agent config

variable "agent_instance_type" {
  default = "m5.large"
}

variable "asg" {
  default = { min : 3, max : 5, desired : 3 } # agent count
}

variable "agent_storage" {
  default = {
    "size" = 100
    type   = "gp2"
  }
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