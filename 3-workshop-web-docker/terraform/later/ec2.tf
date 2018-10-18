#-------------------------------------------------------------------------
# recurso aws_instance para crear un servidor Linux con la última versión 
# de la imagen (AMI) Amazon Linux. 
# El ID de esta imágen proviene del data resource aws_ami.amazon_linux 
#-------------------------------------------------------------------------
resource "aws_instance" "web_docker" {
  ami                    = "${data.aws_ami.web_docker.id}"
  instance_type          = "t2.micro"
  key_name               = "vagrant"
  vpc_security_group_ids = ["${aws_security_group.nginx_docker.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.web_docker.name}"

  tags {
    Name        = "web docker host"
    Description = "Workshop EC2 automation"
  }

  user_data = "${data.template_file.web_docker.rendered}"
}

data "template_file" "web_docker" {
  template = "${file("files/web_docker/user_data.tpl")}"

  vars {
    repository = "${aws_ecr_repository.web_docker.repository_url}"
    tag        = "latest"
  }
}

output "aws_instance_web_docker_public_ip" {
  value = "${aws_instance.web_docker.public_ip}"
}

resource "aws_eip" "web_docker" {
  instance = "${aws_instance.web_docker.id}"
  vpc      = true
}

output "aws_eip_web_docker_public_ip" {
  value = "${aws_eip.web_docker.public_ip}"
}

##################################################################
# recurso aws_security_group_rule para agregar reglas a un grupo 
# de seguridad
##################################################################

resource "aws_security_group" "nginx_docker" {
  name        = "nginxdockerSG"
  description = "Grupo de seguridad servidor nginx"

  tags {
    Name = "Grupo de seguridad servidor nginx"
  }
}

resource "aws_security_group_rule" "nginx_docker_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nginx_docker.id}"
}
