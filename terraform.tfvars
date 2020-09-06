#--------------root/terraform.tfvars----------------------
#Assign the values to the vars defined in variables.tf file

AWS_DEFAULT_REGION = "ap-southeast-2"

vpc_cidr      = "10.123.0.0/16"

public_cidrs  = "10.123.1.0/24"

private_cidrs = "10.123.2.0/24"

accessip      = "0.0.0.0/0"

key_name        = "my_key"

public_key_path = "/home/jenkins/.ssh/aws_rsa.pub"

private_key_path = "/home/jenkins/.ssh/aws_rsa"

instance_count = 1

instance_type = "t2.micro"