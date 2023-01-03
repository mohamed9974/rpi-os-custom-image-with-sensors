#!/bin/bash
# enable bash's debug mode
set -x

# take the IP address of the MQTT broker as an argument
IP=$1
echo "The IP address of the MQTT broker is: ${SERVER_IP}"
# Install dependencies
apt-get update
apt-get install -y python3-pip 
pip3 install paho-mqtt

# Download Telegraf
curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
echo "deb https://repos.influxdata.com/debian buster stable" | tee /etc/apt/sources.list.d/influxdb.list
apt-get update
apt-get install -y telegraf

# Start Telegraf
systemctl start telegraf

# Download and install the emulated sensors
wget https://github.com/mohamed9974/ai4iot/blob/main/services/emulated_senosrs/scripts/simulate.py

chmod +x simulate.py
# Start the emulated sensors
echo ${IP}