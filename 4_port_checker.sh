#!/bin/bash
# Script 4: Port status checker (based on the firewall)
# Name: Alaa Raslan   ID: 443215503   Section: 5551
# Course: IT361 System Administration and Maintenance
#
# What this script does: it takes a port number and tells me if the port
# is OPEN or CLOSED in the firewall (iptables).
#
# How to run it:   sudo ./4_port_checker.sh 22
#
# References: Lecture 10 (Firewalls and iptables), Lecture 5 (case, if),
#             Lecture 7 (grep, head), The Linux Command Line (Shotts, 2019)

# the port number comes after the script name
PORT=$1

if [ "$PORT" = "" ]; then
    echo "Usage: ./4_port_checker.sh port_number"
    exit 1
fi

# the port must be only numbers. case checks the pattern (Lecture 5):
# *[!0-9]* means "there is a character that is not a digit"
case $PORT in
    *[!0-9]*)
        echo "Error: the port must be a number"
        exit 1;;
esac

# a real port is between 1 and 65535
if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Error: the port must be between 1 and 65535"
    exit 1
fi

# reading the firewall rules needs root
if [ "`whoami`" != "root" ]; then
    echo "Error: please run this script with sudo"
    exit 1
fi

# check that iptables works on this computer
if iptables -L -n > /dev/null 2>&1
then
    echo "Checking the firewall (iptables) for port $PORT ..."
else
    echo "Error: I cannot use iptables. Install it with: sudo apt install iptables"
    exit 1
fi

# look in all the rules for this port. In iptables -L -n the port is
# written like "dpt:22" (dpt = destination port). \b makes sure that
# port 22 does not match port 2222
RULE=`iptables -L -n | grep "dpt:$PORT\b"`

if [ "$RULE" = "" ]; then
    # there is no rule for this port, so the default policy of the INPUT
    # chain decides (the first line says: Chain INPUT (policy ACCEPT))
    POLICY=`iptables -L INPUT -n | head -n 1`
    if echo "$POLICY" | grep "policy ACCEPT" > /dev/null
    then
        echo "Port $PORT is OPEN (no rule for it, and the default policy is ACCEPT)"
    else
        echo "Port $PORT is CLOSED (no rule for it, and the default policy blocks it)"
    fi
elif echo "$RULE" | grep "ACCEPT" > /dev/null
then
    echo "Port $PORT is OPEN (there is an ACCEPT rule for it)"
else
    echo "Port $PORT is CLOSED (there is a DROP or REJECT rule for it)"
fi
