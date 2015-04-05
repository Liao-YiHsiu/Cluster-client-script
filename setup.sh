#!/bin/bash

# this is a script to setup a centos to connect NFS and LDAP all together.

if [ $? -ne 1 ] then
   echo "Usage: $0 hostname"
   echo "eg. $0 Hormes"
   exit -1;
fi

name=$1

# setup hostname
hostname $name || exit -1;

# setup hosts
sed -e  's/HOST_NAME/$name/g' hosts  > /etc/hosts || exit -1;

# setup LDAP 
yum -y install openldap-clients nss-pam-ldapd || exit -1;

authconfig --enableldap \
   --enableldapauth \
   --ldapserver=192.168.100.100 \
   --ldapbasedn="dc=DSM2411,dc=speech" \
   --enablemkhomedir \
   --update || exit -1;

#   ca for LDAP
cp -f ldap.conf /etc/openldap/ldap.conf       || exit -1;
cp -f ca.crt    /etc/openldap/cacerts/ca.crt  || exit -1;

# passwd for user change the following file
# synology -> /usr/syno/etc/openldap/slapd-acls.conf
# --------------------------------------------------
# ...
# access to attrs=userPassword
#        by self =xw
# ...
# --------------------------------------------------

# setup NFS
echo "192.168.100.100:/volume2/home_cluster   /home   nfs     defaults        0 0" >> /etc/fstab  || exit -1;

# adduser speech and assign sudoer to speech
id speech 2>&1 | grep "no such user" >/dev/null  && \
   adduser speech

echo "beyondASR" | passwd speech --stdin
usermod -a -G wheel speech

# stop root login
sed -e 's%root:/root:/bin/bash%root:/root:/sbin/nologin%g' /etc/passwd > tmp
cp -f tmp /etc/passwd

reboot
