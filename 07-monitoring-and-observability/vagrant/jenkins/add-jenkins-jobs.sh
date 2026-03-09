#!/bin/bash

# 
# Create Jenkins job
# 

java -jar /home/vagrant/jenkins-cli.jar -s http://192.168.56.11:8080/ -http -auth admin:admin create-job task-manager-ci-api < /vagrant/jenkins/pipeline-api.xml
java -jar /home/vagrant/jenkins-cli.jar -s http://192.168.56.11:8080/ -http -auth admin:admin create-job task-manager-ci-arc < /vagrant/jenkins/pipeline-arc.xml
java -jar /home/vagrant/jenkins-cli.jar -s http://192.168.56.11:8080/ -http -auth admin:admin create-job task-manager-ci-mon < /vagrant/jenkins/pipeline-mon.xml
java -jar /home/vagrant/jenkins-cli.jar -s http://192.168.56.11:8080/ -http -auth admin:admin create-job task-manager-ci-ui < /vagrant/jenkins/pipeline-ui.xml
