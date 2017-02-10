#!/bin/bash -ex

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
tmp=$(mktemp)

# setup hostname
   hostname $name || exit -1;

# setup hosts
   host_ip=$(ifconfig | grep 192 | tr -s ' ' | cut -d ' ' -f 3 | cut -d '.' -f4)
   [ $host_ip == "" ] && host_ip=0
   syn_ip=$(( 100 - host_ip % 4 ))
   sed -e  "s/IP/$syn_ip/g" hosts  > $tmp || exit -1;
   cp $tmp /etc/hosts || exit -1;

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
   sed /etc/sssd/sssd.conf -e 's/\[nss\]/[nss]\noverride_shell = \/bin\/bash/g' > $tmp || exit -1;
   cp $tmp /etc/sssd/sssd.conf

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
   echo "Format the selecting disk..."
   echo "  you need to create one partition table"
   echo "  and write the results to the disk."
   fdisk /dev/$disk || exit 1
   mkfs.xfs -f /dev/${disk}p1 || exit 1
   sleep 1
   uuid=`lsblk -f | grep ${disk}p1 | tr -s ' ' |cut -d ' ' -f 4 | uniq`
   cat /etc/fstab > $tmp || exit -1;
   echo "UUID=$uuid $dir_r xfs defaults,noauto,x-systemd.automount,usrquota,grpquota 0 0" >> $tmp  || exit -1;
   # setup NFS
   echo "Synology:/volume1/home_cluster   /home   nfs     defaults        0 0" >> $tmp  || exit -1;
   echo "Synology:/volume1/share    /share_tar    nfs     defaults        0 0" >> $tmp  || exit -1;
   cp $tmp /etc/fstab || exit -1;
   mount /dev/${disk}p1 $dir_r || exit 1

# adduser speech and assign sudoer to speech
   id $user_r 2>&1 | grep "no such user" >/dev/null  && adduser $user_r 
   usermod -a -G wheel $user_r || exit -1;

# change speech home directory.                                        
   sed -e "s%/home/$user_r%$home_r%g" /etc/passwd > $tmp || exit -1;
   cp -f $tmp /etc/passwd
   mkdir -p $home_r
   echo ". /etc/bashrc" > $home_r/.bashrc
   echo "[ -f ~/.bashrc ] && . ~/.bashrc" > $home_r/.bash_profile
   mkdir -p $home_r/share
   ln -sf $home_r/share /share
   chown -R $user_r:$user_r $home_r
 
# setup default bashrc
   cp bashrc /etc/bashrc

# setup welcome message
   cp motd /etc/motd

# stop root login
   sed -e 's%root:/root:/bin/bash%root:/root:/sbin/nologin%g' /etc/passwd > $tmp || exit -1;
   cp -f $tmp /etc/passwd

# add repository
# if the mirror of KEY is down -> find other mirrors mentioned in wiki
   #rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt  
   rpm --import http://repoforge.mirror.constant.com/RPM-GPG-KEY.dag.txt
   #rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm 
   rpm -Uvh http://repoforge.mirror.constant.com/redhat/el7/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm

# shutdown nouveau for nvidia driver
#   cat /etc/modprobe.d/blacklist.conf > tmp
   echo "blacklist nouveau" > $tmp
   cp $tmp /etc/modprobe.d/blacklist.conf

# turn off selinux for key authentication
   sed /etc/sysconfig/selinux -e 's/enforcing/disabled/g' > $tmp
   cp $tmp /etc/sysconfig/selinux

# set init level = 3
  cp /etc/inittab $tmp
  echo "id:3:initdefault:" >> $tmp
  cp $tmp /etc/inittab

# set max login to 16
  cp /etc/ssh/sshd_config $tmp
  echo "MaxSessions 65"          >> $tmp
  echo "MaxStartups 65:30:100"   >> $tmp
  echo "TCPKeepAlive yes"        >> $tmp
  echo "ClientAliveInterval 60"  >> $tmp
  # speed up ssh connection
  echo "UseDNS no"               >> $tmp
  sed -ri "s/^.*GSSAPIAuthentication.*$/GSSAPIAuthentication no/" $tmp
  cp $tmp /etc/ssh/sshd_config

# setup NFS server and exports /home_local
  firewall-cmd --permanent --zone=public --add-service=nfs
  firewall-cmd --reload 
  systemctl enable nfs-server.service
  systemctl start  nfs-server.service
  echo "/home_local     192.168.100.100/24(rw,async,no_wdelay,insecure,no_root_squash,insecure_locks)" > /etc/exports
  exportfs -a

# install some common tools first
   yum update -y
   yum install -y telnet screen cgdb htop git kernel-devel kernel-headers gcc make java-1.8.0-openjdk-devel.x86_64 graphviz
   yum groupinstall -y "X Window System" "Desktop" "Desktop Platform"
   yum install -y gdm xclock
   yum install -y tree
   yum install -y flac
   yum install -y libattr-devel.x86_64

# turn off gui
systemctl set-default multi-user.target

# setup crontab routine
   echo "*/15 * * * * flock -n /tmp/routine_lock $home_r/Cluster-client-script/routine.sh &>/tmp/routine.log; echo \$? > /tmp/routine.flag" > $tmp
   crontab -u root $tmp

sudo vim /etc/fstab


