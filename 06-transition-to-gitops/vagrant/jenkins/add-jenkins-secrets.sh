#!/bin/bash

# 
# Create Jenkins secrets
# 

CRED_ID=$1
CRED_PASS=$2

cat <<EOF | java -jar /home/vagrant/jenkins-cli.jar -s http://192.168.56.11:8080/ -http -auth admin:admin create-credentials-by-xml system::system::jenkins _
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${CRED_ID}</id>
  <description>${CRED_ID} secret text</description>
  <secret>${CRED_PASS}</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF
