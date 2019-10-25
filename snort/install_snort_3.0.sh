#!/bin/sh

# Setup Snort installation environment
sudo apt-get update && sudo apt-get dist-upgrade -y &&\
cd ~ && rm -rf ~/snort_src && mkdir ~/snort_src && cd ~/snort_src &&\
sudo apt-get install -y build-essential autotools-dev libdumbnet-dev libluajit-5.1-dev libpcap-dev libpcre3-dev zlib1g-dev pkg-config libhwloc-dev &&\

# Install cmake
sudo apt-get remove -y cmake &&\
cd ~/snort_src &&\
wget https://cmake.org/files/v3.10/cmake-3.10.3.tar.gz &&\
tar -xzvf cmake-3.10.3.tar.gz &&\
cd cmake-3.10.3 &&\
./bootstrap &&\
make &&\
sudo make install &&\

sudo apt-get install -y liblzma-dev openssl libssl-dev cpputest libsqlite3-dev uuid-dev &&\
sudo apt-get install -y libtool git autoconf &&\
sudo apt-get install -y bison flex &&\
sudo apt-get install -y libnetfilter-queue-dev &&\

# Install safec for runtime bounds checks on certain legacy C-library calls
cd ~/snort_src &&\
wget https://downloads.sourceforge.net/project/safeclib/libsafec-10052013.tar.gz &&\
tar -xzvf libsafec-10052013.tar.gz &&\
cd libsafec-10052013 &&\
./configure &&\
make &&\
sudo make install &&\

# Install gperftools 2.7 for thread-caching malloc (takes ~5 minutes)
cd ~/snort_src &&\
wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz &&\
tar xzvf gperftools-2.7.tar.gz &&\
cd gperftools-2.7 &&\
./configure &&\
make &&\
sudo make install &&\

# Install Ragel, which is a dependency of Snort's Hyperscan (takes ~5 minutes)
cd ~/snort_src &&\
wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz &&\
tar -xzvf ragel-6.10.tar.gz &&\
cd ragel-6.10 &&\
./configure &&\
make &&\
sudo make install &&\

# Install Boost, which is a dependency of Hyperscan
cd ~/snort_src &&\
wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz &&\
tar -xvzf boost_1_67_0.tar.gz &&\

# Install Hyperscan (takes ~10 minutes)
cd ~/snort_src &&\
wget https://github.com/intel/hyperscan/archive/v4.7.0.tar.gz &&\
tar -xvzf v4.7.0.tar.gz &&\
mkdir ~/snort_src/hyperscan-4.7.0-build &&\
cd hyperscan-4.7.0-build/ &&\
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=~/snort_src/boost_1_67_0/ ../hyperscan-4.7.0 &&\
make &&\
sudo make install &&\

# Install flatbuffers, a memory efficient serializtion library for Snort
cd ~/snort_src &&\
wget https://github.com/google/flatbuffers/archive/v1.9.0.tar.gz -O flatbuffers-1.9.0.tar.gz &&\
tar -xzvf flatbuffers-1.9.0.tar.gz &&\
mkdir flatbuffers-build &&\
cd flatbuffers-build &&\
cmake ../flatbuffers-1.9.0 &&\
make &&\
sudo make install &&\

# Install the DAQ library
cd ~/snort_src &&\
wget https://www.snort.org/downloads/snortplus/daq-2.2.2.tar.gz &&\
tar -xvzf daq-2.2.2.tar.gz &&\
cd daq-2.2.2 &&\
./configure &&\
make &&\
sudo make install &&\

# Install LibDAQ
cd ~/snort_src &&\
git clone https://github.com/snort3/libdaq.git &&\
cd libdaq &&\
./bootstrap &&\
./configure &&\
make &&\
sudo make install &&\

# Update shared libraries
sudo ldconfig &&\

# Install Snort
cd ~/snort_src &&\
git clone git://github.com/snortadmin/snort3.git &&\
cd snort3 &&\
./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc &&\
cd build &&\
make &&\
sudo make install &&\
sudo ln -s /usr/local/bin/snort /usr/local/sbin/snort &&\
snort -V &&\

# Saving PATHs
export LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\; &&\
export SNORT_LUA_PATH=/usr/local/etc/snort &&\
sh -c "echo 'export LUA_PATH=/usr/local/include/snort/lua/\?.lua\;\;' >> ~/.bashrc" &&\
sh -c "echo 'export SNORT_LUA_PATH=/usr/local/etc/snort' >> ~/.bashrc" &&\

# Get Snort Community Rules
cd ~/snort_src/ &&\
wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz &&\
tar -xvzf snort3-community-rules.tar.gz &&\
cd snort3-community-rules &&\
sudo mkdir /usr/local/etc/snort/rules &&\
sudo mkdir /usr/local/etc/snort/builtin_rules &&\
sudo mkdir /usr/local/etc/snort/so_rules &&\
sudo mkdir /usr/local/etc/snort/lists &&\
sudo cp snort3-community.rules /usr/local/etc/snort/rules/ &&\
sudo cp sid-msg.map /usr/local/etc/snort/rules/ &&\

# Enable all the community rules
sudo sed -i "s/^#\salert/alert/g" /usr/local/etc/snort/rules/snort3-community.rules

# Setup IP forwarding for inline mode
sudo sysctl -w net.ipv4.ip_forward=1 &&\
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf &&\

echo 'Done.' &&\

echo 'Run sudo visudo and add Defaults env_keep += "LUA_PATH SNORT_LUA_PATH" to EOF' &&\
echo 'You will need to go ' &&\
echo 'Run snort with `sudo snort -c /usr/local/etc/snort/snort.lua -R /usr/local/etc/snort/rules/snort3-community.rules -Q -i eth0:eth1 -A fast`'
