#!/bin/sh

# Install add-apt-repository
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt-get install -y software-properties-common

# Install Suricata from binary
sudo add-apt-repository ppa:oisf/suricata-stable
sudo apt-get update
sudo apt-get install -y suricata

echo 'Run with `suricata -c suricata.yaml -s signatures.rules -i eth0`'
