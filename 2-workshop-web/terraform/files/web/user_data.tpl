#cloud-config
runcmd:
- 'initctl start web'
- '/etc/init.d/nginx start'