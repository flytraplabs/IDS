#!/usr/bin/env bash

echo "Enter a password for your redis instance. This will be the same password you will use in your shipper.conf."
read PASSWORD
apt-get install default-jdk git redis-server
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.5.deb
sudo dpkg -i elasticsearch-0.90.5.deb
sudo service elasticsearch start
sed -i '/bind 127.0.0.1/d' /etc/redis/redis.conf
echo "masterauth $PASSWORD" >> /etc/redis/redis.conf
/etc/init.d/redis-server restart
sudo mkdir -p /opt/logstash
wget https://download.elasticsearch.org/logstash/logstash/logstash-1.2.1-flatjar.jar -o /opt/logstash/logstash.jar
wget https://flytraplabs.github.com/IDS/indexer.conf -o /opt/logstash/index.conf
sed -i 's/DEFAULT_PASSWORD/$PASSWORD/g' /opt/logstash/indexer.conf
sudo wget https://flytraplabs.github.com/IDS/logstash-init.sh -o /etc/init.d/logstash-init.sh
chmod +x /etc/init.d/logstash-init.sh
initctl reload-configuration