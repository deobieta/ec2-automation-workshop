##################################################################
# recurso aws_security_group para crear grupos de seguridad 
# en este caso utilizamos la VPC default en el region us-east-2.
#
# recurso aws_security_group_rule para agregar reglas a un grupo 
# de seguridad
##################################################################

resource "aws_security_group" "nginx" {
  name        = "nginxSG"
  description = "Grupo de seguridad servidor nginx"

  tags {
    Name = "Grupo de seguridad servidor nginx"
  }
}

resource "aws_security_group_rule" "nginx_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nginx.id}"
}
