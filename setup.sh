#!/bin/bash

# this is a script to setup a centos to connect NFS and LDAP all together.

if [ "$#" -ne 1 ]; then
   echo "Usage: $0 hostname"
   echo "eg. $0 Hormes"
   exit -1;
fi

# echo on
set -x

name=$1
user_r=speech
dir_r=/home_local/
home_r=$dir_r/$user_r

# setup hostname
   hostname $name || exit -1;

# setup hosts
   sed -e  's/HOST_NAME/$name/g' hosts  > tmp || exit -1;
   cp tmp /etc/hosts || exit -1;

# setup LDAP 
   yum -y install openldap-clients nss-pam-ldapd 

   authconfig --enableldap \
      --enableldapauth \
      --ldapserver=192.168.100.100 \
      --ldapbasedn="dc=DSM2411,dc=speech" \
      --enablemkhomedir \
      --update || exit -1;

#   ca for LDAP
   cp -f ldap.conf /etc/openldap/ldap.conf       || exit -1;
   cp -f ca.crt    /etc/openldap/cacerts/ca.crt  || exit -1;
#  update-ca-trust 

#   set login shell as bash
#   /etc/sssd/sssd.conf [nss] -> override_shell = /bin/bash 
   sed /etc/sssd/sssd.conf -e 's/\[nss\]/[nss]\noverride_shell = \/bin\/bash/g' > tmp || exit -1;
   cp tmp /etc/sssd/sssd.conf

# passwd for user change the following file
# synology -> /usr/syno/etc/openldap/slapd-acls.conf
# --------------------------------------------------
# ...
# access to attrs=userPassword
#        by self =xw
# ...
# --------------------------------------------------
#
# automatically create home directory.
# synology -> /etc/exports
# --------------------------------------------------
# /volume1/home *(rw,async,no_wdelay,no_root_squash,insecure,insecure_locks, ...
#                                                   ^^^^^^^^^
# --------------------------------------------------
# synology -> command line
# synoldapserver --automount "192.168.100.100" "/volume1/home_cluster/"

# mount select Disk to /home_local                                     
   mkdir -p $dir_r
   lsblk
   lsblk -f
   echo "Select one disk to format(eg. sda):"                          
   read disk
   fdisk /dev/$disk
   mkfs.ext4 /dev/${disk}1
   sleep 1
   uuid=`lsblk -f | grep ${disk}1 | tr -s ' ' |cut -d ' ' -f 3`
   cat /etc/fstab > tmp || exit -1;
   echo "UUID=$uuid $dir_r ext4 defaults,usrquota,grpquota 0 0" >> tmp  || exit -1;
   # setup NFS
   echo "192.168.100.100:/volume1/home_cluster   /home   nfs     defaults        0 0" >> tmp  || exit -1;
   echo "192.168.100.100:/volume1/corpus   /corpus_tar   nfs     defaults        0 0" >> tmp  || exit -1;
   echo "192.168.100.100:/volume1/share    /share_tar    nfs     defaults        0 0" >> tmp  || exit -1;
   cp tmp /etc/fstab || exit -1;
   mount /dev/${disk}1 $dir_r

   mkdir /corpus_tar
   mkdir /corpus

# adduser speech and assign sudoer to speech
   id $user_r 2>&1 | grep "no such user" >/dev/null  && adduser $user_r 
   echo "setting $user_r passwd"
   passwd $user_r
   usermod -a -G wheel $user_r || exit -1;

# change speech home directory.                                        
   sed -e "s%/home/$user_r%$home_r%g" /etc/passwd > tmp || exit -1;
   cp -f tmp /etc/passwd
   mkdir -p $home_r
   echo ". /etc/bashrc" > $home_r/.bashrc
   echo "[ -f ~/.bashrc ] && . ~/.bashrc" > $home_r/.bash_profile
   chown -R $user_r:$user_r $home_r
 
# setup default bashrc
   cp bashrc /etc/bashrc

# setup welcome message
   cp motd /etc/motd

# stop root login
   sed -e 's%root:/root:/bin/bash%root:/root:/sbin/nologin%g' /etc/passwd > tmp || exit -1;
   cp -f tmp /etc/passwd

# add repository
   rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt  
   rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm 

# shutdown nouveau for nvidia driver
   cat /etc/modprobe.d/blacklist.conf > tmp
   echo "blacklist nouveau" >> tmp
   cp tmp /etc/modprobe.d/blacklist.conf

# setup crontab routine
   echo "* * * * * flock -n /tmp/routine_lock `pwd`/routine.sh" > tmp
   crontab -u root tmp


reboot
