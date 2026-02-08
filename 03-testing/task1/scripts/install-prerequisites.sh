#!/bin/bash

echo "* Update repositories and install Java 21, groovy, and git ..."
apt-get update
apt-get install -y fontconfig openjdk-21-jre groovy git
