#!/bin/sh

# Setup installation environment
sudo apt-get -y update && sudo apt-get upgrade -y
echo 'Setting up installation environment'
install_dir='~/suricata_src'
target_version='4.1.5'

rm -rf `$install_dir` &&\
mkdir `$install_dir` &&\
cd `$install_dir` &&\

# Install dependencies

echo 'Installing dependncies'
sudo apt-get -y install libpcre3 libpcre3-dbg libpcre3-dev \
build-essential autoconf automake libtool libpcap-dev libnet1-dev \
libyaml-0-2 libyaml-dev zlib1g zlib1g-dev libcap-ng-dev libcap-ng0 \
make libmagic-dev libjansson-dev libjansson4 pkg-config &&\

sudo apt-get install -y libnetfilter-queue-dev libnetfilter-queue1 libnfnetlink-dev &&\


# Install suricata from source
echo 'Installing Suricata' &&\
cd `$install_dir` &&\
wget "https://www.openinfosecfoundation.org/download/suricata-$target_version.tar.gz" &&\
tar -xvzf "suricata-$target_version.tar.gz" &&\
cd "suricata-$target_version" &&\
./configure --enable-nfqueue --prefix=/usr --sysconfdir=/etc --localstatedir=/var &&\
make &&\
sudo make install &&\
sudo make install-conf &&\
sudo ldconfig &&\

echo 'Done.'
