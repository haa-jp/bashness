#!/bin/bash
# Based on rgin script by Paulo E. Espinosa G
# - Thanks Amigo!
# ------------------------------------------------------------------------------

 
### Enter username and IP(or hostname) for REMOTE machine
echo -n "Enter remote username: "
read USR
echo -n "Remote username is set to $USR  "
case $usr in
esac
echo ""
 
echo -n "Enter remote ip/host address: "
read HOST
echo -n "Remote ip/host is set to $HOST  "
case $usr in
esac
 
#echo -n "Default SSH port is 22 if you want to change it please open ssh_gen with your favourite text editor and change "PORT=" PORT_NUMMER"
 
echo -n "Enter PORT: "
read PORT
echo -n "Remote port is $PORT  "
case $usr in
esac
 
echo -n "Your config is :User = $USR  Host = $HOST Port = $PORT "
 
#PORT="22"
NEWKEY="yes"
 
# Generate SSH keys RSA
makekey () {
if [ $NEWKEY == "yes" ]; then
ssh-keygen -t rsa -f ~/.ssh/identity
fi
}
 
# Check for file "authozed_keys" if file is not there create it.
 
checkfile () {
if [ -f ~/.ssh/authorized_keys ]; then
touch ~/.ssh/authorized_keys
fi
}
 
# Check for ".ssh" if dir is not there create it.
upload () {
cat ~/.ssh/identity.pub | ssh -p $PORT $USR@$HOST 'sh -c "if [ ! -d .ssh ] ; then mkdir .ssh ; chmod 700 .ssh ; fi
cat - >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"'
echo "Done..................... "
}
 
## Main Menu
press_enter () {
echo ""
echo -n "Press Enter to continue"
read
clear
}
 
selection=
until [ "$selection" = "0" ]; do
echo ""
echo "******* PROGRAM MENU **********"
echo "1 - Generate & Upload New Key"
echo "2 - Upload Old Key"
echo ""
echo "0 - exit "
echo ""
echo -n "Enter choose: "
read selection
echo ""
case $selection in
1 ) checkfile ; makekey ; upload ;;
2 ) upload ;;
0 ) exit ;;
 
    * ) echo "Please enter 1, 2 or 0"; press_enter
 
esac
done
 
exit 0
 
#END
