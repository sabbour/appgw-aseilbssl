#!/bin/bash
internalzonename=$1
aseinternalip=$2
bindinternalip=$3

# Replace /etc/resolv.conf with our resolv.conf to temporarily change the DNS to 8.8.8.8
cp /etc/resolv.conf /etc/resolv.conf.bak
cp resolv.conf /etc/resolv.conf

# Run apt-get update and install bind
apt-get update -y && apt-get install -y bind9

# Replace /etc/bind/named.conf.options which will now add Google DNS as forwarders for external DNS queries
cp named.conf.options /etc/bind/named.conf.options

# Replace /etc/bind/named.conf.local which will now load the zone file from /etc/bind/zones/{internalzonename}.db
sed -i 's/{_internalzonename_}/$internalzonename/g' named.conf.local
cp named.conf.local /etc/bind/named.conf.local

# Replace /etc/bind/zones/{internalzonename}.db
mkdir -p /etc/bind/zones
sed -i "s/{_internalzonename_}/$internalzonename/g" zone.db
sed -i "s/{_aseinternalip_}/$aseinternalip/g" zone.db
sed -i "s/{_bindinternalip_}/$bindinternalip/g" zone.db
cp zone.db /etc/bind/zones/${internalzonename}.db

# Check the configuration (will output in console)
named-checkzone internal.sabbour.pw /etc/bind/zones/internal.sabbour.pw.db

# Restore /etc/resolv.conf
cp /etc/resolv.conf.bak /etc/resolv.conf && rm /etc/resolv.conf.bak

# Restart bind
service bind9 restart