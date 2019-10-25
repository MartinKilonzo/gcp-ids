#!/bin/sh

# Update and upgrade
sudo apt-get update -y && sudo apt-get upgrade -y &&\

# Install Snort dependencies
sudo apt-get install openssh-server ethtool build-essential libpcap-dev libpcre3-dev libdumbnet-dev bison flex zlib1g-dev liblzma-dev openssl libssl-dev liblua5.2-dev &&\
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz &&\
tar -zxvf daq-2.0.6.tar.gz && cd daq-2.0.6 && sudo ./configure && sudo make && sudo make install &&\

# Install Snort (takes ~10 minutes)
cd ~ &&\
wget https://www.snort.org/downloads/snort/snort-2.9.14.tar.gz &&\
tar -zxvf snort-2.9.14.tar.gz && cd snort-2.9.14 && sudo . &&\
/configure && sudo make && sudo make install &&\

# Clean up
cd ~ &&\
rm -rf daq-2.0.6* snort-2.9.14* &&\
echo 'Done!'
