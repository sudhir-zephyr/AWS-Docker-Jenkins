#--------------Networking/outputs.tf----------------------

output "Public_Subnet_ID" {
  value = "${aws_subnet.my_public_subnet.id}"
}

output "Private_Subnet_ID" {
  value = "${aws_subnet.my_private_subnet.id}"
}

output "Public_Subnet_IP" {
  value = "${aws_subnet.my_public_subnet.cidr_block}"
}

output "Private_Subnet_IP" {
  value = "${aws_subnet.my_private_subnet.cidr_block}"
}

output "Public_SG" {
  value = "${aws_security_group.my_public_sg.id}"
}

output "Public_Instance_ID" {
  value = "${join(", ", aws_instance.docker_server.*.id)}"
}

output "Public_Instance_IP" {
  value = "${join(", ", aws_instance.docker_server.*.public_ip)}"
}
