#!/bin/sh

sudo apt-get update && apt-get install -y nmap hping3

TARGET_IP=`gcloud compute instances list --filter='name="internal-service"' | tail -n+2 | awk '{print $4}'`

sudo nmap -PN -sF -vv -d1 $TARGET_IP -oA nmap_sf
sudo nmap -PN -sX -vv -d1 $TARGET_IP -oA nmap_sx
ping -c 3 -p 2b2b2b415448300d $TARGET_IP
hping3 -V -c 10000 -d 120 -S -w 64 -p 445 -s 445 -flood --rand-source $TARGET_IP
