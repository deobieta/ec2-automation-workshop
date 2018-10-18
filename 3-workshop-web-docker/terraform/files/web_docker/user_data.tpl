#cloud-config
runcmd:
- 'aws ecr get-login --region us-east-2 --no-include-email | tr -d "\r" > docker.sh && /bin/sh docker.sh'
- 'docker pull ${repository}:${tag}'
- 'docker run -d --name=web -p 5000:5000 ${repository}:${tag}'