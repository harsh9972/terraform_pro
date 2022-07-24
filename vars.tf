# 2 subnets as we need two availability zone 1A & 1B
variable "subnet-1a" {
    type = string
    default = "ca-central-1a"
  
}

variable "subnet-1b" {
    type = string
    default = "ca-central-1b"
  
}

#4 subnet (2 private & 2 Public)
variable "subnet-1a-cidr_block" {
    type = string
    default = "10.10.1.0/24"
  
}

variable "subnet-2a-cidr_block" {
    type = string
    default = "10.10.3.0/24"
  
}

variable "subnet-1b-cidr_block" {
    type = string
    default = "10.10.2.0/24"
  
}

variable "subnet-2b-cidr_block" {
    type = string
    default = "10.10.4.0/24"
  
}

variable "ami" {
    type = string
    default = "ami-0003b7cfcbc725663"
}
variable "instance-type" {
    type = string
    default = "t2.micro"
  
}

variable "key-name" {
    type = string
    default = "terraformkey"
}