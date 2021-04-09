#!/usr/bin/env bash

nguests=$1
guestNumber=$2
memory=$3
ipAddressStart=$4

# Install some utilities that we will need
apt-get -y update
apt-get -y install unzip
apt-get -y install curl

# Install java
apt-get -y install default-jre

# Get Elasticsearch - Manual
# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.12.0-linux-x86_64.tar.gz
# tar -xzf elasticsearch-7.12.0-linux-x86_64.tar.gz

# Install & Start up elasticsearch
# /vagrant/scripts/elastic.sh $nguests $guestNumber $memory $ipAddressStart
