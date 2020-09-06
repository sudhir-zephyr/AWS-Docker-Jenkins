#--------------Networking/varaiables.tf----------------------

variable "AWS_DEFAULT_REGION" {}

variable "vpc_cidr" {}

variable "public_cidrs" {}

variable "private_cidrs" {}

variable "accessip" {}


#--------------compute/varaiables.tf----------------------

variable "key_name" {}

variable "public_key_path" {}

variable "private_key_path" {}
         
variable "instance_count" {}

variable "instance_type" {}

