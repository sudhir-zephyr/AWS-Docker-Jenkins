#******************AWS Provider Definition******************
provider "aws" {
  region = "${var.AWS_DEFAULT_REGION}"
}

#******************Networking Resources**********************
data "aws_availability_zones" "available" {}

resource "aws_vpc" "my_vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true  
  enable_dns_support    = true

  tags {
    Name = "my_vpc"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  tags {
    Name = "my_igw"
  }
}

resource "aws_route_table" "my_public_rt" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_igw.id}"
  }

  tags {
    Name = "my_public_rt"
  }
}

resource "aws_subnet" "my_public_subnet" {
  vpc_id                  = "${aws_vpc.my_vpc.id}"
  cidr_block              = "${var.public_cidrs}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "my_public_subnet"
  }  
}

resource "aws_route_table_association" "my_public_rt_assoc" {
  subnet_id      = "${aws_subnet.my_public_subnet.id}"
  route_table_id = "${aws_route_table.my_public_rt.id}"
}

resource "aws_subnet" "my_private_subnet" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "${var.private_cidrs}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "my_private_subnet"
  }
}

resource "aws_route_table" "my_private_route_table" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  tags {
    Name = "my_private_rt"
}
}

resource "aws_route_table_association" "my_private_rt_assoc" {
  subnet_id      = "${aws_subnet.my_private_subnet.id}"
  route_table_id = "${aws_route_table.my_private_route_table.id}"
}

resource "aws_security_group" "my_public_sg" {
  name        = "my_public_sg"
  description = "used for public instances"
  vpc_id      = "${aws_vpc.my_vpc.id}"
 
  #For SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }
    
  #For JENKINS
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.accessip}"]
  }

  #HTTP
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#******************Compute Resources************************
data "aws_ami" "server_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "my_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "docker_server" {
  count         = "${var.instance_count}"
  instance_type = "${var.instance_type}"
  ami           = "${data.aws_ami.server_ami.id}"

  tags {
    Name = "docker_host"
  }
  
  key_name               = "${aws_key_pair.my_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.my_public_sg.id}"]
  subnet_id              = "${aws_subnet.my_public_subnet.id}"

  #Connect to the host using ssh with pvt key and public IP address to bootstrap using remote proivisioner
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${file(var.private_key_path)}"
    host        = "${aws_instance.docker_server.public_ip}"
  } 

  #Run the shell commands on the remote EC2 instance in AWS
  provisioner "remote-exec" {

    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker && sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo docker pull jenkins/jenkins",
      "mkdir -p jenkins_data/jenkins_home",
    ]
  }

  #Copies the docker-compose file to EC2
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "$PWD/jenkins_data/docker-compose.yml"
  }

  #Run the shell commands on the remote EC2 instance in AWS
  provisioner "remote-exec" {

    inline = [
      "docker-compose -f $PWD/jenkins_data/docker-compose.yml up -d",
    ]
  }
}