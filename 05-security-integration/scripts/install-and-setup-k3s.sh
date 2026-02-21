#!/bin/bash

echo "* Prepare the registries.yaml ..."
mkdir -pv /etc/rancher/k3s
cat > /etc/rancher/k3s/registries.yaml <<EOF
mirrors:
  "192.168.56.12:5000":
    endpoint:
      - "http://192.168.56.12:5000"

configs:
  "192.168.56.12:5000":
    tls:
      insecure_skip_verify: true
EOF

echo "* Install the k3s distribution ..."
curl -sfL https://get.k3s.io | sh -s - server --bind-address=192.168.56.12 --flannel-iface=enp0s8 --node-ip=192.168.56.12

echo "* Install kubectl and helm binaries ..."
curl -LO https://dl.k8s.io/release/v1.34.3/bin/linux/amd64/kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

echo "* Copy the credentials for accessing k3s ..."
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
mkdir /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -Rv vagrant:vagrant .kube
