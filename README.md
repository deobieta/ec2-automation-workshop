# Automatización de infraestructura en EC2


**Saltar a tema:**

* [Resumen del taller](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#resumen-del-taller)
* [Crear usuario administrador para el taller](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#crear-usuario-administrador-para-el-taller)
* [Establece llaves de acceso en la configuracion de Terraform](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#establece-llaves-de-acceso-en-la-configuracion-de-terraform)
* [Crear servidor mgmt](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#crear-servidor-mgmt)
* [Crear imagen Web con Aplicacion en Docker](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#crear-imagen-web-con-aplicacion-en-docker)
* [Crear repositorio en ECR y construir imagen de Docker](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#crear-repositorio-en-ecr-y-construir-imagen-de-docker)
* [Crear servidor Web con aplicacion en Docker](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#crear-servidor-web-con-aplicacion-en-docker)
* [Limpiar taller](https://github.com/deobieta/ec2-automation-workshop/blob/master/README.md#limpiar-taller)


## Resumen del taller

El taller tiene como finalidad hacer una introducción al uso de herramientas de automatización de infraestructura en [EC2](https://aws.amazon.com/ec2/). 

Antes de comenzar el taller es necesario completar los siguientes pasos:

* [Tener una cuenta en AWS](<https://aws.amazon.com>)
* [Instalar Terraform](<https://www.terraform.io/downloads.html>)

IMPORTANTE: La primera parte del taller crea una instancia con las herramientas necesarias para llevar a cabo el taller pero si deseas usar las herramientas directamente desde tu máquina puedes hacerlo.

Las herramientas que utilizaremos en el taller son:

* [Terraform](<https://www.terraform.io/>) (Herramienta para construir, cambiar y versionar infraestructura de manera segura y eficiente.)
* [Packer](<https://www.packer.io/>) (Herramienta para crear imágenes de máquina idénticas para múltiples plataformas desde una única configuración de fuente)
* [Ansible](<https://www.ansible.com/>) (Lenguaje de automatización simple que puede describir perfectamente una infraestructura de aplicaciones de TI
)
* [Docker](<https://docker.com/>) (Herramienta diseñada para facilitar la creación, implementación y ejecución de aplicaciones mediante el uso de contenedores)


## Crear usuario administrador para el taller

Entra a la cuenta que vas a utilizar en el taller y navega a la consola de usuarios [IAM](https://console.aws.amazon.com/iam/home?region=us-east-2#/users).


Agrega un nuevo usuario que se llame "workshop"

![user output](/readme-images/iam/1.png)

Dar permisos de administrador al nuevo usuario (AdministratorAccess).

IMPORTANTE: Por practicidad le damos estos permisos al usuario, en el mundo real siempre es mejor dar el menor número de permisos a un usuario o rol.

![perms output](/readme-images/iam/2.png)

Descargar las llaves de acceso para hacer llamadas al API de AWS.

![keys output](/readme-images/iam/3.png)

## Establece llaves de acceso en la configuracion de Terraform

Para establecer las llaves de acceso puedes exportar las credenciales como variables de ambiente. 

    $ export AWS_ACCESS_KEY_ID="AKIAJ3RAVUDDQWJADQSQ"
    $ export AWS_SECRET_ACCESS_KEY="BpXA8AbiC1vgZUTVrKzsxB/zRnPCaIe8YjP0Q9VDu"

También puedes usar el editor de tu elección, abrir el archivo 1-workshop-mgmt/terraform/provider.tf, descomentar las dos lineas de las llaves de accesso y reemplazar el texto "ACCESS_KEY_HERE" y "SECRET_KEY_HERE".

[![asciicast](https://asciinema.org/a/r0vqkbAWd9Ov8JMlMs87ZXHUg.png)](https://asciinema.org/a/r0vqkbAWd9Ov8JMlMs87ZXHUg)

## Crear servidor mgmt

    $ cd ec2-automation-workshop/1-workshop-mgmt/terraform/
    $ terraform init
    $ terraform apply

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

Terraform creará un plan de ejecución y al final pregunta si quieres aplicar el plan, escribe "yes" para aplicar los cambios.

[![asciicast](https://asciinema.org/a/hGcOmcoULta4FlYRE6Xk2VVxy.png)](https://asciinema.org/a/hGcOmcoULta4FlYRE6Xk2VVxy)

Al aplicar el plan, Terraform dará dos valores de salida, uno es la dirección IP del servidor mgmt que acabamos de crear y que utilizaremos para crear más infraestructura desde el interior de nuestra VPC default, el otro valor es el identificador de la imagen (AMI) que utilizaremos para crear una imagen (AMI) personalizada y a partir de ella crear nuestro servidor Web. 

## Crear servidor Web 

Entra al servidor via Secure Shell utilizando la llave privada insegura de [Vagrant](https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant) y el usuario de Amazon Linux.

    $ chmod 0600 ssh-keys/vagrant
    $ ssh -i ssh-keys/vagrant ec2-user@18.223.2.127
    $ cd ~/2-workshop-web/packer/
    $ packer build web.json

[![asciicast](https://asciinema.org/a/eTOuvt9i5A4hVu4pmGqNxtsGe.png)](https://asciinema.org/a/eTOuvt9i5A4hVu4pmGqNxtsGe)

Una vez creada la imagen pre-configurada podemos aprovisionar un servidor que sirva nuestra applicación Web. El servidor consiste de un servidor Web (NGINX) que sirve como proxy para servir una aplicación hecha en Python Flask. Para mas detalles de la aplicación ver el archivo de configuración del servidor que es 2-workshop-web/packer/ansible/web-playbook.yml

    $ cd ~/2-workshop-web/terraform/
    $ terraform init
    $ terraform apply

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

[![asciicast](https://asciinema.org/a/ilhuvPwPvu8hWzi92OUq5wQ7o.png)](https://asciinema.org/a/ilhuvPwPvu8hWzi92OUq5wQ7o)

Nuestra imagen está configurada con una versión de nuestra aplicación en específico, al crear un servidor a partir de esta imagen lo único que hay que hacer es levantar los servicios necesarios para empezar a servir nuestra aplicación. Los servicios los levantamos utilizando [user-data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) en un [templete de Terraform](https://www.terraform.io/docs/providers/template/d/file.html). El templete es 2-workshop-web/terraform/files/web/user_data.tpl.

Utiliza la dirección IP de la salida aws_eip_web_public_ip en cualquier navegador para revisar que la aplicación está sirviendo de forma correcta. Puede tardar algunos minutos en verse correctamente.


**Hacer otra versión de la aplicación y cambiar EIP.

## Crear imagen Web con Aplicacion en Docker

Entra al servidor via Secure Shell utilizando la llave privada insegura de Vagrant y el usuario de Amazon Linux.

    $ chmod 0600 ssh-keys/vagrant
    $ ssh -i ssh-keys/vagrant ec2-user@18.223.2.127
    $ cd ~/3-workshop-web-docker/packer/
    $ packer build web-docker.json


[![asciicast](https://asciinema.org/a/J6aOAHt633ciXztkACpv8jBHc.png)](https://asciinema.org/a/J6aOAHt633ciXztkACpv8jBHc)

Nuestra imagen con NGINX y Docker Engine está lista, pero antes de crear el servidor que sirva nuestra aplicación debemos crear un repositorio de Docker para alojar y crear la imagen de Docker. Para mas detalles del servidor ver el archivo de configuración que es 3-workshop-web-docker/packer/ansible/web-docker-playbook.yml


## Crear repositorio en ECR y construir imagen de Docker.

    $ cd ~/3-workshop-web-docker/terraform/
    $ terraform init
    $ terraform apply

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes
    

[![asciicast](https://asciinema.org/a/ehg3iv8UZkabseemRYerl25ak.png)](https://asciinema.org/a/ehg3iv8UZkabseemRYerl25ak)

Después de crear nuestro repositorio es tiempo de crear nuestra imagen de Docker:

    $ cd ~/python/
    $ sudo docker build -t local/web .

Para probar la imagen:

    $ sudo docker run --name=web -d  -p 5000:5000 local/web
    $ sudo docker ps 
    CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
    d0681b75c144        local/web           "gunicorn -b :5000 w…"   About a minute ago   Up About a minute   0.0.0.0:5000->5000/tcp   web

    $ curl "http://localhost:5000"

Etiquetar imagen:
    
    $ sudo docker tag local/web:latest 059715603496.dkr.ecr.us-east-2.amazonaws.com/web-docker:latest

Iniciar sesión en [ECR](https://aws.amazon.com/ecr/):

    $ sudo aws ecr get-login --region us-east-2 --no-include-email

Este comando tiene como salida algo parecido a lo siguiente:

    docker login -u AWS -p eyJwYXlsb2FkIjoiNmZ3eW5PZk4xRGJ3Zm0yU3lLZnp2N0VEQ2Jma1o2VTVpMXVUREV2Zlo0Zk92VG83bnFOT1M1NS9iUG9PS1cvaEZrV2VkSW1ZMUNEcisyUkNWNVlxMnJSOG1kWVdGTkxqMUFLcHhrRm85bjc0WndEckdmVmdPUkJUSXJJZldkbytBYXAxODZGODJ2eVFOSWZnK1laYm5PZXdNRmdkUXg4ZlkzSTNtTFNnbDl4K0hzRkhhWUwweGRTbjZMcmRlWGRJU3c4eXZwQ3lCdWtQOWNqU0FiSzIzcDdNa0JxdVM2NXh3N21OejFVSGU1R2JQYVpyWCtKcDNqbmNXR1c4Nlhya2pIODBWOWh4WC94R2x2SzJUdGUvQXNJVjdvbXFBNDJGR0lIYTNOeitwS2QyR1JwL0Vxck5rZEpVZUI0VTJ5K0FsRFZiZi9FWm5PVVNTcxfQ== https://059715603496.dkr.ecr.us-east-2.amazonaws.com

Para iniciar sesión en ECR, copia y pega la salida anterior utilizando sudo.

    $ sudo docker login -u AWS -p eyJwYXlsb2FkIjoiNmZ3eW5PZk4xRGJ3Zm0yU3lLZnp2N0VEQ2Jma1o2VTVpMXVUREV2Zlo0Zk92VG83bnFOT1M1NS9iUG9PS1cvaEZrV2VkSW1ZMUNEcisyUkNWNVlxMnJSOG1kWVdGTkxqMUFLcHhrRm85bjc0WndEckdmVmdPUkJUSXJJZldkbytBYXAxODZGODJ2eVFOSWZnK1laYm5PZXdNRmdkUXg4ZlkzSTNtTFNnbDl4K0hzRkhhWUwweGRTbjZMcmRlWGRJU3c4eXZwQ3lCdWtQOWNqU0FiSzIzcDdNa0JxdVM2NXh3N21OejFVSGU1R2JQYVpyWCtKcDNqbmNXR1c4Nlhya2pIODBWOWh4WC94R2x2SzJUdGUvQXNJVjdvbXFBNDJGR0lIYTNOeitwS2QyR1JwL0Vxck5rZEpVZUI0VTJ5K0FsRFZiZi9FWm5PVVNTcxfQ== https://059715603496.dkr.ecr.us-east-2.amazonaws.com

    WARNING! Using --password via the CLI is insecure. Use --password-stdin.
    WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
    Configure a credential helper to remove this warning. See
    https://docs.docker.com/engine/reference/commandline/login/#credentials-store

    Login Succeeded

Push de imagen de Docker:

    $ sudo docker push 059715603496.dkr.ecr.us-east-2.amazonaws.com/web-docker:latest
    961af540d51d: Pushed 
    c2783771f5e3: Pushed 
    b341396c46e3: Pushed 
    a256825872fb: Pushed 
    1acdea66e0dc: Pushed 
    f743dc78f43b: Pushed 
    c7358e96e74b: Pushed 
    2c30600325be: Pushed 
    df64d3292fd6: Pushed 
    latest: digest: sha256:b692acdf518533eaa9d7017f40629d5de7d98710680b7ef6c24ba5231c96c8c6 size: 2201


[![asciicast](https://asciinema.org/a/fAE65czJqZAfoGCeB3NvLoeix.png)](https://asciinema.org/a/fAE65czJqZAfoGCeB3NvLoeix)

## Crear servidor Web con aplicacion en Docker

Una vez creada la imagen pre-configurada podemos aprovisionar un servidor que sirva nuestra applicación Web. La máquina consiste de un servidor Web (NGINX) que funciona como proxy para servir una aplicación hecha en Python Flask que corre dentro de un contenedor de Docker. Para más detalles de la aplicación ver el archivo de configuración del servidor que es 2-workshop-web/packer/ansible/web-playbook.yml

    $ cd ~/3-workshop-web-docker/terraform/
    
 Es importante que la configuración del servidor (later/ec2.tf) no esté presente hasta tener nuestra imagen (AMI), repositorio de ECR e imagen de Docker creadas de antemano, de otra forma nuestra aplicación del plan de Terraform fallaría por no tener los recursos necesarios. Ahora que están creados, movemos la configuración de Terraform del servidor al directorio donde aplicamos los cambios de Terraform:

    $ mv later/ec2.tf .
    $ terraform init
    $ terraform apply

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

[![asciicast](https://asciinema.org/a/rVlfWlzfPrlHXBMo0oMd0UHIZ.png)](https://asciinema.org/a/rVlfWlzfPrlHXBMo0oMd0UHIZ)

Utiliza la dirección IP de la salida aws_eip_web_docker_public_ip en cualquier navegador para revisar que la aplicación está funcionando de forma correcta. Puede tardar algunos minutos en verse correctamente.

**Hacer otra versión de la aplicación en otro imagen de Docker y cambiar contenedor que corre actualmente por la versión nueva de imagen.


## Limpiar taller

    $ cd ~/3-workshop-web-docker/terraform/
    $ terraform destroy

    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    $ cd ~/2-workshop-web/terraform/
    $ terraform destroy
    
    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

    $ exit

    $ cd ec2-automation-workshop/1-workshop-mgmt/terraform/
    $ terraform destroy
    
    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes

![user output](/readme-images/mgc.gif)


Elimina las imagenes (AMIs) creadas:


![user output](/readme-images/ec2/1.png)


