#!/bin/bash
#Concept taken from fodor.xyz
#Install from Graylog Docs http://docs.graylog.org/en/2.3/pages/installation/os/ubuntu.html


#Prerequisites
apt update && sudo apt upgrade -y
apt -y install apt-transport-https openjdk-8-jre-headless uuid-runtime python-software-properties debconf-utils pwgen


#MongoDB (version included in 16.04 LTS)
apt -y install mongodb-server


#Elasticsearch 5.x 
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
apt update && apt -y install elasticsearch

#Elasticsearch config
sed -i -e 's/# cluster.name: my-application$/cluster.name: graylog/g' /etc/elasticsearch/elasticsearch.yml
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service


#Graylog 2.3.x
wget https://packages.graylog2.org/repo/packages/graylog-2.3-repository_latest.deb
dpkg -i graylog-2.3-repository_latest.deb
apt update && apt -y install graylog-server

#Graylog config
sed -i -e "s/rest_listen_uri = http:\/\/127.0.0.1:9000\//rest_listen_uri = http:\/\/${IPV4}:9000\//g" /etc/graylog/server/server.conf
sed -i -e "s/#web_listen_uri = http:\/\/127.0.0.1:9000\//web_listen_uri = http:\/\/${IPV4}:9000\//g" /etc/graylog/server/server.conf
SECRET=$(pwgen -s 96 1)
sed -i -e 's/password_secret =.*/password_secret = '$SECRET'/' /etc/graylog/server/server.conf
PASSWORD=$(echo -n $ADMIN_PASSWORD | shasum -a 256 | awk '{print $1}')
sed -i -e 's/root_password_sha2 =.*/root_password_sha2 = '$PASSWORD'/' /etc/graylog/server/server.conf


#Cleanup & Startup
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
