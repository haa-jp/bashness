#!/bin/bash
# Shell script to display statistics for web server running processes
# Add this script etc/profile.d to run every time you login
# ------------------------------------------------------------------------------
echo '----------------------------------------------------'
echo '       Most importantly, is APACHE running'
echo '----------------------------------------------------'
ps -ef |grep '[h]ttpd'

echo '----------------------------------------------------'
echo '       NGINX'
echo '----------------------------------------------------'
ps -ef |grep nginx

echo '----------------------------------------------------'
echo '       APACHE TOMCAT'
echo '----------------------------------------------------'
ps -ef |grep tomcat

echo '----------------------------------------------------'
echo '       VARNISH http accelerator'
echo '----------------------------------------------------'
ps -ef |grep varnish

echo '----------------------------------------------------'
echo '       MEMCASHE'
echo '----------------------------------------------------'
ps -ef |grep memcached

echo '----------------------------------------------------'
echo '       MySQL'
echo '----------------------------------------------------'
#ps -ef |grep '[m]ysqld'
if ps aux | grep -q "[m]ysqld" ;
   then echo "All is good" ;
   else echo '! DATABASE IS NOT RUNNING !';
 fi
                                        
