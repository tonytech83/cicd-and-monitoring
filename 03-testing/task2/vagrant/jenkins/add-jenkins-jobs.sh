#!/bin/bash

# Path to CLI
CLI_JAR="/home/vagrant/jenkins-cli.jar"
URL="http://192.168.99.102:8080/"
AUTH="admin:admin"

echo "Waiting for Jenkins to fully initialize Pipeline classes..."
while ! java -jar $CLI_JAR -s $URL -auth $AUTH list-plugins | grep -q "workflow-job"; do
    echo "Pipeline plugin not ready yet... waiting 5 seconds"
    sleep 5
done

echo "Jenkins is ready. Creating jobs..."

java -jar $CLI_JAR -s $URL -http -auth $AUTH create-job ci-api < /vagrant/jenkins/api-job.xml
java -jar $CLI_JAR -s $URL -http -auth $AUTH create-job ci-archiver < /vagrant/jenkins/archiver-job.xml
java -jar $CLI_JAR -s $URL -http -auth $AUTH create-job ci-frontend < /vagrant/jenkins/frontend-job.xml
java -jar $CLI_JAR -s $URL -http -auth $AUTH create-job ci-monitor < /vagrant/jenkins/monitor-job.xml
