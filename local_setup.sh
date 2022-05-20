#!/bin/sh

read -p 'Server IP address: ' SERVER_IP
echo Adding $SERVER_IP with host name \"devserver\" to the hosts file
echo -e "\n$SERVER_IP\tdevserver" | sudo tee -a /etc/hosts