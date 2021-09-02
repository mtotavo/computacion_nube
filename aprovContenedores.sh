#!/bin/bash

echo "Instalacion de apache2 en web1C"
sudo lxc exec web1C -- sudo apt install apache2 -y
sudo lxc exec web1C -- sudo systemctl enable apache2

echo "Creacion de index1.html y envio a contenedor"
sudo touch index1.html

sudo cat << TEST > /home/vagrant/index1.html
<html>
<head>
<title>Web1C</title>
</head>
<body>
<h1>Bienvenido a la pagina Web 1</h1>
<p> mi contenedor LXD</p>
</body>
</html>
TEST
sudo lxc file push index1.html web1C/var/www/html/index.html
sudo lxc exec web1C -- sudo service apache2 restart


echo "Instalacion de apache2 en web2C"
sudo lxc exec web2C -- sudo apt install apache2 -y
sudo lxc exec web2C -- sudo systemctl enable apache2

echo "Creacion de index2.html y envio a contenedor"
sudo touch index2.html

sudo cat << TEST > /home/vagrant/index2.html
<html>
<head>
<title>Web2C</title>
</head>
<body>
<h1>Bienvenido a la pagina Web 2</h1>
<p> mi contenedor LXD</p>
</body>
</html>
TEST
sudo lxc file push index2.html web2C/var/www/html/index.html
sudo lxc exec web2C -- sudo service apache2 restart


echo "Instalacion de apache2 en web3C"
sudo lxc exec web3C -- sudo apt install apache2 -y
sudo lxc exec web3C -- sudo systemctl enable apache2

echo "Creacion de index3.html y envio a contenedor"
sudo touch index3.html

sudo cat << TEST > /home/vagrant/index3.html
<html>
<head>
<title>Web3C</title>
</head>
<body>
<h1>Bienvenido a la pagina Web de Respaldo #1</h1>
<p> mi contenedor LXD</p>
</body>
</html>
TEST
sudo lxc file push index3.html web3C/var/www/html/index.html
sudo lxc exec web3C -- sudo service apache2 restart

echo "Instalacion de apache2 en web4C"
sudo lxc exec web4C -- sudo apt install apache2 -y
sudo lxc exec web4C -- sudo systemctl enable apache2

echo "Creacion de index4.html y envio a contenedor"
sudo touch index4.html

sudo cat << TEST > /home/vagrant/index4.html
<html>
<head>
<title>Web4C</title>
</head>
<body>
<h1>Bienvenido a la pagina Web de Respaldo #2</h1>
<p> mi contenedor LXD</p>
</body>
</html>
TEST
sudo lxc file push index4.html web4C/var/www/html/index.html
sudo lxc exec web4C -- sudo service apache2 restart

echo "Instalacion de HAProxy"
sudo lxc exec haproxyC -- sudo apt install haproxy -y
sudo lxc exec haproxyC -- sudo systemctl enable haproxy

echo "Traer, modificar y enviar archivo de configuracion de HAProxy"
sudo lxc file pull haproxyC/etc/haproxy/haproxy.cfg

sudo cat << TEST > /home/vagrant/haproxy.cfg
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL). This list is from:
        #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
        # An alternative list with additional directives can be obtained from
        #  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
        ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
        ssl-default-bind-options no-sslv3

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http


backend web-backend
   balance roundrobin
   stats enable
   stats auth admin:admin
   stats uri /haproxy?stats

   server web1 240.3.0.29:80 check
   server web2 240.3.0.92:80 check

   #Servidores web de respaldo
   option allbackups
   server web3 240.3.0.241:80 check backup
   server web4 240.3.0.63:80 check backup

backend web-backend-full
   balance roundrobin
   stats enable
   stats auth admin:admin
   stats uri /haproxy?stats

   server web1 240.3.0.29:80 check
   server web2 240.3.0.92:80 check
   server web3 240.3.0.241:80 check
   server web4 240.3.0.63:80 check

frontend http
  bind *:80
  #Sí hay mas de 10 o mas conexion, cambia al backend donde funcionan los 4 con roundrobin
  acl mucho_trafico fe_conn gt 10
  #acl mucho_trafico nb_srv(web-backend)
  use_backend web-backend-full if mucho_trafico
  default_backend web-backend

TEST

sudo lxc file push haproxy.cfg haproxyC/etc/haproxy/haproxy.cfg

echo "mensaje de error 503"
sudo touch 503.http
sudo cat << TEST > /home/vagrant/503.http
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html><body><h1>503 No esta funcionando</h1>
Perdon por el mal servicio. Espere pacientemente :)
</body></html>

TEST
sudo lxc file push 503.http haproxyC/etc/haproxy/errors/503.http

echo "Reiniciar servicio haproxy"
sudo lxc exec haproxyC -- sudo systemctl stop haproxy
sudo lxc exec haproxyC -- sudo systemctl start haproxy

echo "Redireccionamiento de maquina haproxy a contenedor haproxyC"
sudo lxc config device add haproxyC http proxy listen=tcp:0.0.0.0:5055 connect=tcp:127.0.0.1:80