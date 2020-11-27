# -*- mode: ruby -*-
# vi: set ft=ruby :

# No VB Guest available
IMAGE_NAME = "alpine-linux/alpine-x86_64"
IMAGE_VERSION = "3.12.0"
N = 2

Vagrant.configure("2") do |config|

    # config.ssh.insert_key = false
    config.vbguest.auto_update = false

    config.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 2
        v.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end

    config.vm.define "kmaster", primary: true do |master|
        master.vm.box = IMAGE_NAME
        master.vm.box_version = IMAGE_VERSION
        master.vm.network "private_network", ip: "192.168.10.10"
        master.vm.hostname = "kmaster"
        master.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
        master.vm.synced_folder '.', '/vagrant', disabled: true
        master.vm.provision "file", source: "scripts/.", destination: "/home/vagrant"
        master.vm.provision :shell, path: "scripts/bootstrap.sh", privileged: true
        master.vm.provision :shell, path: "scripts/master.sh", privileged: true
        master.trigger.after :provision do |trigger|
          trigger.name = "create token"
          trigger.run = {"inline": "/bin/bash -c 'vagrant ssh kmaster -- \"kubeadm token create --print-join-command 2>&1 | grep ^kubeadm\" > scripts/join_cluster.sh'"}
        end
    end


    (1..N).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.box_version = IMAGE_VERSION
            node.vm.network "private_network", ip: "192.168.10.#{i + 10}"
            node.vm.hostname = "node-#{i}"
            node.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
            node.vm.synced_folder '.', '/vagrant', disabled: true
            node.vm.provision "file", source: "scripts/.", destination: "/home/vagrant"
            node.vm.provision :shell, path: "scripts/bootstrap.sh", privileged: true
            node.vm.provision :shell, path: "scripts/join_cluster.sh", privileged: true
            node.trigger.after :provision do |trigger|
              trigger.name = "Join cluster"
              trigger.run = {"inline": "/bin/bash -c 'cat scripts/join_cluster.sh | sed \"s|^|sudo |\" | vagrant ssh node-#{i} -- '"}
            end
        end
    end
end
