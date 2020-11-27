#!/bin/bash
set -e

# Initialize Kubernetes
echo "Initialize Kubernetes Cluster"
kubeadm config images pull

# NOTE --pod-network-cidr=10.244.0.0/16 is as same as default flannel CNI network
# Let's wait for kubeadm init timeout
kubeadm init --cri-socket /run/containerd/containerd.sock \
             --apiserver-advertise-address=192.168.10.10 \
             --pod-network-cidr=10.244.0.0/16 \
             --v=5 || true

status=$(rc-service kubelet start)

if ! echo $status | grep -qi "already"
then
    # start kubeadm process again
    kubeadm init --cri-socket /run/containerd/containerd.sock \
                 --apiserver-advertise-address=192.168.10.10 \
                 --pod-network-cidr=10.244.0.0/16 \
                 --v=5 \
                 --ignore-preflight-errors=Port-6443,Port-10259,Port-10257,Port-10250,Port-2379,Port-2380,DirAvailable--var-lib-etcd,FileAvailable--etc-kubernetes-manifests-kube-apiserver.yaml,FileAvailable--etc-kubernetes-manifests-kube-controller-manager.yaml,FileAvailable--etc-kubernetes-manifests-kube-scheduler.yaml,FileAvailable--etc-kubernetes-manifests-etcd.yaml
fi    

# Copy Kube admin config
echo "Copy kube admin config to user .kube directory"

# for root user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# for vagrant user
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "Deploy Flannel CNI"
kubectl apply -f https://gist.githubusercontent.com/rahulinux/e85cc1210f12b3e00cec75ee5ea8989e/raw/9b32d82c324e079f8b1f69efbd54a421edc800ec/vagrant-kube-flannel.yml
# Orignal https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

