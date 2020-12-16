#!/bin/sh

# User configuration
SERVER_IP_ADDR="192.168.0.4"        # IP address to use for your server. Typically 192.168.0.x or 192.168.1.x
SERVER_IP_NETMASK_CIDR="16"
GATEWAY_IP_ADDR="192.168.0.1"
DOMAIN="None"                       # If your home network has a domain name, like home.example.com, enter it here
DNS_SERVER_1="9.9.9.9"
DNS_SERVER_2="149.112.112.112"

# Download our new dnsmasq config file from our repository before we lose Internet connection
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/dnsmasq.conf > ~/dnsmasq.conf
curl https://raw.githubusercontent.com/ssnseawolf/easydns-linux/master/netplan.yaml > ~/netplan.yaml

# Replace variables in our newly downloaded config file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/dnsmasq.conf
sed -i "s/DOMAIN/$DOMAIN/" ~/dnsmasq.conf
sed -i "s/domain=None/#domain=None/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_1/$DNS_SERVER_1/" ~/dnsmasq.conf
sed -i "s/DNS_SERVER_2/$DNS_SERVER_2/" ~/dnsmasq.conf

# Replace variables in our newly downloaded netplan file
sed -i "s/SERVER_IP_ADDR/$SERVER_IP_ADDR/" ~/netplan.yaml
sed -i "s/SERVER_IP_NETMASK_CIDR/$SERVER_IP_NETMASK_CIDR/" ~/netplan.yaml
sed -i "s/GATEWAY_IP_ADDR/$GATEWAY_IP_ADDR/" ~/netplan.yaml

# Download blocklist for first time
BLACKLIST_URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt"
curl $BLACKLIST_URL | sudo tee /etc/dnsmasq.blacklist.txt > /dev/null

# Download dnsmasq before we cut the network connection
sudo apt install -y dnsmasq --download-only

#sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo apt install -y dnsmasq

# Apply our config and netplan files
sudo rsync ~/dnsmasq.conf /etc/dnsmasq.conf --remove-source-files
sudo rm /etc/netplan/*.yaml
sudo rsync ~/netplan.yaml /etc/netplan/netplan.yaml

# Update ablock list as a cronjob
# Create a cron job to update adlist every day at midnight with a 1 hour random offset
CRONJOB="0 1 * * * root    perl -le 'sleep rand 3600' && curl $BLACKLIST_URL | tee /etc/dnsmasq.blacklist.txt"
echo "$CRONJOB" | sudo tee -a /etc/crontab

# Lazy machine restart
reboot