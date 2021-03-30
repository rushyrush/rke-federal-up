variable "agent_instance_type" {
  default = "m5.large"
}
variable "server_instance_type" {
  default = "m5.large"
}
variable "asg" {
  default = { min : 3, max : 5, desired : 3 }
}
variable "servers" {
  default = 1
}
variable "ami" {
  default = "ami-84556de5"
}
variable "block_device_mappings" {
  default = {
    "size" = 100
    type   = "gp2"
  }
}