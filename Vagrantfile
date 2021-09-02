# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
 config.vm.define :haproxy do |haproxy|
  haproxy.vm.box = "bento/ubuntu-20.04"
  haproxy.vm.network :private_network, ip: "192.168.50.2"
  haproxy.vm.provision "shell", path: "aprovContenedores.sh"
  haproxy.vm.hostname = "haproxy"
 end

 config.vm.define :web1 do |web1|
  web1.vm.box = "bento/ubuntu-20.04"
  web1.vm.network :private_network, ip: "192.168.50.3"
  web1.vm.hostname = "web1"
 end
end
