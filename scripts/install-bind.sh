#!/bin/bash
internalzonename=$1
aseinternalip=$2
bindinternalip=$3
timestamp=$(date +%s)

echo "Executing at $timestamp"

# Run apt-get update and install bind
echo 'Updating apt-get and installing BIND'
apt-get update -y && apt-get install -y bind9

# Replace /etc/bind/named.conf.options which will now add Google DNS as forwarders for external DNS queries
echo 'Override named.conf'
cp named.conf.options /etc/bind/named.conf.options

# Replace /etc/bind/named.conf.local which will now load the zone file from /etc/bind/zones/{internalzonename}.db
echo "Override named.conf.local to load zone file from/etc/bind/zones/$internalzonename.db and string replace {_internalzonename_} with $internalzonename"
sed -i "s/{_internalzonename_}/$internalzonename/g" named.conf.local
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

echo "Making sure BIND has permissions to read the zone file"
chown bind:bind /etc/bind/zones/${internalzonename}.db

# Check the configuration (will output errors in console)
echo "Checking zone config"
named-checkzone ${internalzonename} /etc/bind/zones/${internalzonename}.db

# Check the configuration (will output errors in console)
echo "Checking named config"
named-checkconf /etc/bind/named.conf.local

# Restart bind
echo "Restart BIND"
service bind9 restart

