resource "aws_eip" "web" {
  instance = "${aws_instance.web.id}"
  vpc      = true
}

output "aws_eip_web_public_ip" {
  value = "${aws_eip.web.public_ip}"
}
