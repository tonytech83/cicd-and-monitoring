#!/bin/bash

echo "* Add Jenkins repository key ..."
wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "* Add Jenkins repository ..."
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "* Update repositories and install Jenkins ..."
apt-get update
apt-get install -y jenkins
