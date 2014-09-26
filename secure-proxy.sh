#!/bin/bash
# iptables setup script for any linux machine- run this to create /etc/sysconfig/iptables
# No internal network ( a stand alone configuration )
# usage: ./scripts/secure-proxy -[start | stop]
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Set up Variables here (calculate ip addresses to generalize this script)

SSHPORT=1876
MYSQL=3306
EXT_FACE=eth0               # External Interface
EXT_IP=$(ifconfig $EXT_FACE| grep inet| cut -f2 -d:| cut -f1 -d" ")
LOCAL=127.0.0.0/8           # local network (full scope)
DMZ_NET=192.168.3.0/24      # Primary network
DOMAIN_NET=192.168.1.0/24   # Second nic card potential

VPN_NET=10.242.10.0/24      #used for remote access via vpn connection client

ADMIN=75.75.75.76
#FRIEND=01.02.03.04
#FRIEND2=11.22.33.44
echo "EXT_FACE=$EXT_FACE"
echo "EXT_IP=$EXT_IP"
sleep 3

# Use CIDR notation (/24 for class C, /16 for class B, and /8 for class A)

# ------------------------------------------------------------------------------
# Flush rules before setting these new ones up
# ------------------------------------------------------------------------------
# This section will open everything back up in case you really screwed up

IPT="/sbin/iptables"

# reset the default policies in the filter table
# -t filter is the default (so do not need to reference it)

$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

# reset the default policies in the nat table

$IPT -t nat -P PREROUTING ACCEPT
$IPT -t nat -P POSTROUTING ACCEPT
$IPT -t nat -P OUTPUT ACCEPT

# reset the default policies in the mangle table

$IPT -t mangle -P PREROUTING ACCEPT
$IPT -t mangle -P OUTPUT ACCEPT

# flush all the rules in the filter, nat, and mangle tables

$IPT -F
$IPT -t nat -F
$IPT -t mangle -F

# erase all chains that's not default in filter, nat, and mangle tables
# -X with no argument will delete all non-default chains in the table

$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

if [ "$1" = "stop" ] ;then
echo "Firewall completly stopped!  WARNING: THIS HOST HAS NO FIREWALL RUNNING"
echo "That means we are not operating as a gateway anymore either"
exit 0
fi

# ------------------------------------------------------------------------------
# Check on continued communication with outside link - ESTABLISHED, RELATED connections
# ------------------------------------------------------------------------------
#$IPT -A INPUT -p TCP -m state --state ESTABLISHED,RELATED -j LOG --log-prefix " ESTABLISHED IN ACCEPT "
# REMOTE SSHPORT added for Len - Thanks for all your help!
$IPT -A INPUT -p TCP -m state --state ESTABLISHED,RELATED -j ACCEPT

#$IPT -A OUTPUT -p TCP -m state --state ESTABLISHED,RELATED -j LOG --log-prefix " ESTABLISHED OUT ACCEPT "
$IPT -A OUTPUT -p TCP -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 80 -j LOG --log-prefix " INPUT syn ACCEPT "
#$IPT -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
$IPT -A INPUT -m state --state INVALID -j LOG --log-prefix " INVALID STATE IN DROP "
$IPT -A INPUT -m state --state INVALID -j REJECT

# Allow all local
#$IPT -A INPUT -s $LOCAL -p tcp --syn -j LOG --log-prefix " LOCAL ACCEPT "
$IPT -A INPUT -s $LOCAL -p tcp --syn -j ACCEPT
$IPT -A OUTPUT -s $LOCAL -p tcp --syn -j ACCEPT

# Setup remote access for admins and friends
# Leave these lines exactly as they are - They are used in sed to modify the
/sbin/iptables -A INPUT  -s $ADMIN-p tcp --dport $SSHPORT -j ACCEPT
/sbin/iptables -A OUTPUT -s $ADMIN -p tcp --sport $SSHPORT -j ACCEPT
/sbin/iptables -A OUTPUT -s $ADMIN -p tcp --dport $SSHPORT -j ACCEPT

#$IPT -A INPUT  -s $FRIEND  -p tcp --dport $SSHPORT -j ACCEPT
#$IPT -A OUTPUT -s $FRIEND  -p tcp --sport $SSHPORT -j ACCEPT
#$IPT -A OUTPUT -s $FRIEND  -p tcp --dport $SSHPORT -j ACCEPT
#$IPT -A INPUT  -s $FRIEND2 -p tcp --dport $SSHPORT -j ACCEPT
#$IPT -A OUTPUT -s $FRIEND2 -p tcp --sport $SSHPORT -j ACCEPT
#$IPT -A OUTPUT -s $FRIEND2 -p tcp --dport $SSHPORT -j ACCEPT


# Allow for generic SSH - Disable when not in use
#$IPT -A INPUT -p tcp --dport 22 -j ACCEPT
#$IPT -A OUTPUT -p tcp --sport 22 -j ACCEPT

# Filter ssh sessions
$IPT -A INPUT -s $DOMAIN_NET -p tcp  --dport 22 -j ACCEPT
$IPT -A OUTPUT -s $DOMAIN_NET -p tcp  --sport 22 -j ACCEPT
$IPT -A INPUT -s $DMZ_NET -p tcp  --dport $SSHPORT -j ACCEPT
$IPT -A OUTPUT -s $DMZ_NET -p tcp  --sport $SSHPORT -j ACCEPT
$IPT -A INPUT -s $DOMAIN_NET -p tcp  --dport $SSHPORT -j ACCEPT
$IPT -A OUTPUT -s $DOMAIN_NET -p tcp  --sport $SSHPORT -j ACCEPT
$IPT -A INPUT -s $VPN_NET -p tcp --dport $SSHPORT -j ACCEPT
$IPT -A OUTPUT -s $VPN_NET -p tcp --sport $SSHPORT -j ACCCEPT

$IPT -A INPUT -p tcp -m tcp --dport 22 -j LOG --log-prefix " SSH Illegal IP REJECT "
$IPT -A INPUT -p tcp -m tcp --dport 22 -j REJECT
$IPT -A INPUT -p tcp -m tcp --dport $SSHPORT -j LOG --log-prefix " SSH Illegal IP REJECT "
$IPT -A INPUT -p tcp -m tcp --dport $SSHPORT -j REJECT

$IPT -A INPUT -j LOG --log-prefix "All INPUT LOG "
$IPT -A OUTPUT -j LOG --log-prefix "All OUTPUT LOG  "
# ------------------------------------------------------------------------------
# Destinations - ACCEPT, DROP, DENY
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Allows ICMP communication with the following machines (includes pinging)
# ------------------------------------------------------------------------------

$IPT -A INPUT -s $LOCAL -p icmp -j ACCEPT
$IPT -A INPUT -s $DMZ_NET -p icmp -j ACCEPT
$IPT -A INPUT -s $DOMAIN_NET -p icmp -j ACCEPT
$IPT -A INPUT -s $VPN_NET -p icmp -j ACCEPT

# Allow ping out
$IPT -A OUTPUT -s $EXT_IP -p icmp -j ACCEPT

# Allow traceroute out
$IPT -A INPUT -d $EXT_IP -p icmp --icmp-type 11 -j ACCEPT
$IPT -A OUTPUT -s $EXT_IP -p udp -j ACCEPT
$IPT -A INPUT -s $DOMAIN_NET -p udp -j ACCEPT
$IPT -A OUTPUT -d $DOMAIN_NET -p udp -j ACCEPT

# Drop all others
#$IPT -A INPUT -s 0/0 -p icmp -j LOG --log-prefix " ICMP  DROP "
$IPT -A INPUT -s 0/0 -p icmp -j DROP

# Allow local mail off of webserver2 to nwsexch03
$IPT -A INPUT -s $LOCAL -p tcp -m tcp --dport 25 --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -s $EXT_IP -p tcp -m tcp --dport 25 --tcp-flags SYN,RST,ACK SYN -j ACCEPT

# allowing mail from anyone
$IPT -A INPUT -p tcp -m tcp --dport 25 --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 25 --tcp-flags SYN,RST,ACK SYN -j LOG --log-prefix " Mail to Who - REJECT "
$IPT -A INPUT -p tcp -m tcp --dport 25 --tcp-flags SYN,RST,ACK SYN -j REJECT

# Wed Nov  5 06:23:20 CST 2008 LAL so strangers can not pop3 - also we do not have a pop3 service running.
$IPT -A INPUT -p tcp -m tcp --dport 110 --tcp-flags SYN,RST,ACK SYN -j LOG --log-prefix " POP from Outside DROP "
$IPT -A INPUT -p tcp -m tcp --dport 110 --tcp-flags SYN,RST,ACK SYN -j DROP

# Allow clock update through ntpd port 123
$IPT -A INPUT -p tcp  --dport 123 -j LOG --log-prefix " NTP update "
$IPT -A INPUT -s $EXT_IP -p tcp -m tcp --dport 123 --tcp-flags SYN,RST,ACK SYN -j ACCEPT

# Alow samba with Inside rooms
# Block out ports that are know problems 445 and 139 (tcp) SMB over the internet (also 135)
$IPT -A INPUT -s $DOMAIN_NET -p tcp --dport 135 -j ACCEPT
$IPT -A INPUT -s $LOCAL -p tcp -m tcp --dport 135  -j ACCEPT
$IPT -A INPUT -p tcp  --dport 135  -j LOG --log-prefix " SMB hack135 "
$IPT -A INPUT -p tcp  --dport 135  -j REJECT
# Microsoft does not create a normal session through this port so we can not test for
# --tcp-flags SYN,RST,ACK SYN -j ACCEPT --- So just ACCEPT our internal machines through port 139
$IPT -A INPUT -s $DOMAIN_NET -p tcp --dport 139 -j ACCEPT
$IPT -A INPUT -s $LOCAL -p tcp --dport 139 -j ACCEPT
$IPT -A INPUT -p tcp  --dport 139  -j LOG --log-prefix " SMB hack139 "
$IPT -A INPUT -p tcp  --dport 139  -j REJECT
$IPT -A INPUT -s $DOMAIN_NET -p tcp  --dport 445 -j ACCEPT
$IPT -A INPUT -s $LOCAL -p tcp --dport 445 -j ACCEPT
$IPT -A INPUT -p tcp  --dport 445  -j LOG --log-prefix " SMB hack445 "
$IPT -A INPUT -p tcp  --dport 445  -j REJECT

# Allow access to named server - Limit with external and internal views on named.conf
$IPT -A INPUT  -p udp --dport 53 -j ACCEPT
# If you reject udp --sport 53 things become really broken
#$IPT -A INPUT  -p udp --sport 53 -j LOG --log-prefix "UDP 53 sport ACCEPT "
$IPT -A INPUT  -p udp --sport 53 -j ACCEPT
$IPT -A INPUT  -p tcp --dport 53 -j LOG --log-prefix "TCP 53 dport ACCEPT "
$IPT -A INPUT  -p tcp --dport 53 -j ACCEPT
$IPT -A INPUT  -p tcp --sport 53 -j LOG --log-prefix "TCP 53 sport ACCEPT "
$IPT -A INPUT  -p tcp --sport 53 -j ACCEPT

# for splunk trial
$IPT -A INPUT  -s $DOMAIN_NET -p tcp --dport 9997 -j ACCEPT
$IPT -A OUTPUT -s $DOMAIN_NET -p tcp --dport 9997 -j ACCEPT

# Log tcp Secure https requests
$IPT -A INPUT -p tcp  --dport 443 -j LOG --log-prefix " HTTPS Input request ACCEPT "
$IPT -A INPUT -p tcp -m tcp --dport 443 --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A OUTPUT -p tcp  --dport 443 -j LOG --log-prefix " HTTPS Output request ACCEPT "
$IPT -A OUTPUT -p tcp -m tcp --dport 443 --tcp-flags SYN,RST,ACK SYN -j ACCEPT

# Tomcat - This would only be for tests on Tomcats directly
$IPT -A INPUT -p tcp -m tcp --dport 8080 --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 8082 --tcp-flags SYN,RST,ACK SYN -j ACCEPT

# Plone - added to test installation of Plone 3.5 - changes from origional 8080 to prevent conflict
#         with tomcat application server. to change Plone ports refer to promary Plone / Zope config
#         /usr/local/Plone/zinstance/buildout.cfg
# $IPT -A INPUT -p tcp -m tcp --dport 8880 --tcp-flags SYN,RST,ACK SYN -j ACCEPT


# Drop MYSQL requests that come from outside
# Activate for a SPECIFIC source IP address
$IPT -A INPUT -s 192.168.1.34 -p tcp -m tcp --dport $MYSQL --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -s 192.168.1.1  -p tcp -m tcp --dport $MYSQL --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -s 192.168.1.80 -p tcp -m tcp --dport $MYSQL --tcp-flags SYN,RST,ACK SYN -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport $MYSQL --tcp-flags SYN,RST,ACK SYN -j LOG --log-prefix "MySQL REJECT "
#$IPT -A INPUT -p tcp -m tcp --dport $MYSQL --tcp-flags SYN,RST,ACK SYN -j REJECT

# ------------------------------------------------------------------------------
# DROP everything else unless it is port 80
# ------------------------------------------------------------------------------
$IPT -A INPUT -p tcp -m tcp ! --dport 80 --tcp-flags SYN,RST,ACK SYN -j LOG --log-prefix " INPUT syn REJECT "
$IPT -A INPUT -p tcp -m tcp ! --dport 80 --tcp-flags SYN,RST,ACK SYN -j REJECT

# ======================= END of INPUT RULESET ======================================

# Nothing to FORWARD
# Monitor mail being forwarded out
#$IPT -A FORWARD -p tcp --dport 25 -j LOG --log-prefix " FORWARD dpt 25 "

# Continue ACCEPT on all connections we initiated internally
#$IPT -A FORWARD -p TCP -m state --state ESTABLISHED,RELATED -j ACCEPT

# ALLOW all FORWARD Traffic  Special case
#/sbin/iptables -A FORWARD -j ACCEPT


# To keep things working while we are hardening out rulsets
$IPT -t filter -P INPUT ACCEPT
$IPT -t filter -P OUTPUT ACCEPT
$IPT -t filter -P FORWARD ACCEPT

# List out the results
$IPT -nL |more
