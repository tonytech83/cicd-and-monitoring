#!/bin/bash

echo "* Install SOPS ..."
curl -LO https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64
mv sops-v3.11.0.linux.amd64 /usr/local/bin/sops
chmod +x /usr/local/bin/sops

echo "* Install age ..."
apt-get install -y age

echo "* Install helm secrets plugin ..."
sudo -u vagrant -- helm plugin install https://github.com/jkroepke/helm-secrets/releases/download/v4.7.4/secrets-4.7.4.tgz --verify=false

echo "* Generate age key ..."
sudo -u vagrant -- age-keygen -o /vagrant/keys.txt
sudo -u vagrant -- mkdir -p /home/vagrant/.config/sops/age/
sudo -u vagrant -- cp /vagrant/keys.txt /home/vagrant/.config/sops/age/

echo "* Add the public key to the .sops.yaml file ..."
sed -i "s/<KEY>/$(grep 'public key' /home/vagrant/.config/sops/age/keys.txt | cut -d ':' -f 2 | tr -d ' ')/g" /vagrant/apps/task-manager-base/.sops.yaml 

echo "* Encrypt the secrets.yaml file ..."
sudo -u vagrant -- helm secrets encrypt /vagrant/apps/task-manager-base/charts/task-manager/secrets.yaml > /vagrant/apps/task-manager-base/charts/task-manager/secrets.enc.yaml
