#-------------------------------------------------------------------------
# Data sources permiten recuperar o computar los datos para usarlos en 
# cualquier otra parte de la configuración de Terraform. 
# El uso de "data sources" permite que una configuración de Terraform 
# se base en información definida fuera de Terraform, o definida por otra 
# configuración separada de Terraform.
#-------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*ebs"]
  }
}

output "aws_ami_amazon_linux_id" {
  value = "${data.aws_ami.amazon_linux.id}"
}

#-------------------------------------------------------------------------
# recurso  aws_key_pair para crear una llave publica con la que podremos 
# entrar a la máquina creada. Por practicidad utilizamos una llave 
# insegura del proyecto Vagrant de Hashicorp. 
#
# ¡¡¡ NO UTILIZAR ESTA LLAVE EN NINGUN OTRO SEVIDOR FUERA DE ESTE TALLER !!!
#-------------------------------------------------------------------------
resource "aws_key_pair" "vagrant" {
  key_name   = "vagrant"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
}

#-------------------------------------------------------------------------
# recurso aws_instance para crear un servidor Linux con la última versión 
# de la imagen (AMI) Amazon Linux. 
# El ID de esta imágen proviene del data resource aws_ami.amazon_linux 
#-------------------------------------------------------------------------
resource "aws_instance" "mgmt" {
  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "t2.micro"
  key_name               = "${aws_key_pair.vagrant.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.mgmt.name}"

  tags = {
    Name        = "mgmt host"
    Description = "Workshop EC2 automation"
  }

  provisioner "file" {
    source      = "ansible/mgmt-setup-playbook.yml"
    destination = "/home/ec2-user/mgmt-setup-playbook.yml"
    
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../../ssh-keys/vagrant")}"
    }
  }

  provisioner "file" {
    source      = "../../2-workshop-web"
    destination = "/home/ec2-user"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../../ssh-keys/vagrant")}"
    }
  }

  provisioner "file" {
    source      = "../../3-workshop-web-docker"
    destination = "/home/ec2-user"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../../ssh-keys/vagrant")}"
    }
  }

  provisioner "file" {
    source      = "../../python"
    destination = "/home/ec2-user"

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../../ssh-keys/vagrant")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "pip install --user ansible",
      "/home/ec2-user/.local/bin/ansible-playbook /home/ec2-user/mgmt-setup-playbook.yml",
    ]

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../../ssh-keys/vagrant")}"
    }
  }
}

output "aws_instance_mgmt_public_ip" {
  value = "${aws_instance.mgmt.public_ip}"
}

#--------------------------------------------------------------
# SystemAdministrator IAM policy attachment
#--------------------------------------------------------------
resource "aws_iam_instance_profile" "mgmt" {
  name = "mgmt"
  role = "${aws_iam_role.mgmt.name}"
}

resource "aws_iam_role" "mgmt" {
  name = "mgmt"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

##################################################################
# recurso aws_security_group para crear grupos de seguridad 
# en este caso utilizamos la VPC default en el region us-east-2.
#
# recurso aws_security_group_rule para agregar reglas a un grupo 
# de seguridad
##################################################################

resource "aws_security_group" "ssh" {
  name        = "sshSG"
  description = "Grupo de seguridad ssh"

  tags = {
    Name = "Grupo de seguridad ssh"
  }
}

data "http" "myip" {
  url = "http://soporteweb.com"
}

resource "aws_security_group_rule" "ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["${format("%s/32", "${data.http.myip.body}")}"]

  #cidr_blocks       = ["${var.commandout}"]

  security_group_id = "${aws_security_group.ssh.id}"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ssh.id}"
}

#--------------------------------------------------------------
# AmazonEC2FullAccess IAM policy attachment
#--------------------------------------------------------------
resource "aws_iam_policy_attachment" "AmazonEC2FullAccess" {
  name = "AmazonEC2FullAccess-policy-attachment"

  #FIXME: clean up reace condition
  users      = []
  roles      = ["${aws_iam_role.mgmt.name}"]
  groups     = []
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

#--------------------------------------------------------------
# AmazonECS_FullAccess IAM policy attachment
#--------------------------------------------------------------
resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  name = "AmazonEC2ContainerRegistryFullAccess-policy-attachment"

  #FIXME: clean up reace condition
  users      = []
  roles      = ["${aws_iam_role.mgmt.name}"]
  groups     = []
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_policy_attachment" "mgmtIAM" {
  name = "mgmtIAM-policy-attachment"

  #FIXME: clean up reace condition
  users      = []
  roles      = ["${aws_iam_role.mgmt.name}"]
  groups     = []
  policy_arn = "${aws_iam_policy.mgmtIAM.arn}"
}

data "aws_iam_policy_document" "mgmtIAM" {
  statement {
    sid = "1"

    actions = [
      "iam:DeletePolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:ListEntitiesForPolicy",
      "iam:GetPolicyVersion",
      "iam:GetPolicy",
      "iam:ListRolePolicies",
      "iam:CreatePolicy",
      "iam:GetUserPolicy",
      "iam:PutUserPolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:AttachRolePolicy",
      "iam:ListAttachedUserPolicies",
      "iam:GetUser",
      "iam:CreateUser",
      "iam:AttachUserPolicy",
      "iam:PassRole",
      "iam:ListInstanceProfiles",
      "iam:GetRole",
      "iam:GetInstanceProfile",
      "iam:PutRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DetachUserPolicy",
      "iam:DeleteInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfilesForRole",
      "iam:AddRoleToInstanceProfile",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "mgmtIAM" {
  name        = "mgmtIAM"
  description = ""
  policy      = "${data.aws_iam_policy_document.mgmtIAM.json}"
}
