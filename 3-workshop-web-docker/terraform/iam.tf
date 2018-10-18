#--------------------------------------------------------------
# AmazonEC2ContainerRegistryReadOnly IAM policy attachment
#--------------------------------------------------------------
resource "aws_iam_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  name       = "SystemAdministrator-policy-attachment"
  users      = []
  roles      = ["${aws_iam_role.web_docker.name}"]
  groups     = []
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#--------------------------------------------------------------
# AmazonEC2ContainerRegistryReadOnly IAM policy attachment
#--------------------------------------------------------------
resource "aws_iam_instance_profile" "web_docker" {
  name = "web_docker"
  role = "${aws_iam_role.web_docker.name}"
}

resource "aws_iam_role" "web_docker" {
  name = "web_docker"

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

