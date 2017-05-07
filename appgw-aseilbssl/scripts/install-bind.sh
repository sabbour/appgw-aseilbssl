#!/bin/bash
internalzonename=$1
aseinternalip=$2
bindinternalip=$3
timestamp=4

# Replace /etc/resolv.conf with our resolv.conf to temporarily change the DNS to 8.8.8.8
echo 'Temporarily overriding DNS to be 8.8.8.8'
cp /etc/resolv.conf /etc/resolv.conf.bak
cp resolv.conf /etc/resolv.conf

# Run apt-get update and install bind
echo 'Updating apt-get and installing BIND'
apt-get update -y && apt-get install -y bind9

# Replace /etc/bind/named.conf.options which will now add Google DNS as forwarders for external DNS queries
echo 'Override named.conf'
cp named.conf.options /etc/bind/named.conf.options

# Replace /etc/bind/named.conf.local which will now load the zone file from /etc/bind/zones/{internalzonename}.db
echo "Override named.conf.local to load zone file from/etc/bind/zones/$internalzonename.db and string replace {_internalzonename_} with $internalzonename"
sed -i 's/{_internalzonename_}/$internalzonename/g' named.conf.local
cp named.conf.local /etc/bind/named.conf.local

# Replace /etc/bind/zones/{internalzonename}.db
echo "Creating /etc/bind/zones directory"
mkdir -p /etc/bind/zones

echo "String replace {_internalzonename_} with $internalzonename, {_aseinternalip_} with $aseinternalip, {_bindinternalip_} with $bindinternalip, {_timestamp_} with $timestamp in zone.db"
sed -i "s/{_internalzonename_}/$internalzonename/g" zone.db
sed -i "s/{_aseinternalip_}/$aseinternalip/g" zone.db
sed -i "s/{_bindinternalip_}/$bindinternalip/g" zone.db
sed -i "s/{_timestamp_}/$timestamp/g" zone.db

echo "Override /etc/bind/zones/$internalzonename"
cp zone.db /etc/bind/zones/${internalzonename}.db

# Restore /etc/resolv.conf
echo "Restore /etc/resolv.conf"
cp /etc/resolv.conf.bak /etc/resolv.conf && rm /etc/resolv.conf.bak

# Restart bind
echo "Restart BIND"
service bind9 restart

# Check the configuration (will output in console)
echo "Checking config"
named-checkzone ${internalzonename} /etc/bind/zones/${internalzonename}.db
