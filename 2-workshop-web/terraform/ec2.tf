#-------------------------------------------------------------------------
# recurso aws_instance para crear un servidor Linux con la última versión 
# de la imagen (AMI) Amazon Linux. 
# El ID de esta imágen proviene del data resource aws_ami.amazon_linux 
#-------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = "${data.aws_ami.web.id}"
  instance_type          = "t2.micro"
  key_name               = "vagrant"
  vpc_security_group_ids = ["${aws_security_group.nginx.id}"]

  tags {
    Name        = "web host"
    Description = "Workshop EC2 automation"
  }

  user_data = "${data.template_file.web.rendered}"
}

data "template_file" "web" {
  template = "${file("files/web/user_data.tpl")}"
}

output "aws_instance_web_public_ip" {
  value = "${aws_instance.web.public_ip}"
}
