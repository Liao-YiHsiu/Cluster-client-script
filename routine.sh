#!/bin/bash

# routine jobs ... use crontab to execute

# check if it is already executing...

# -------------------------------------------------------
# setup home_local directory and quota for ldap users
dir_r=/home_local/
curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
tmp=$(mktemp)
threads=$(nproc)

PATH=$PATH:/usr/sbin

set -x
#quotacheck -avfug || true
#quotaon -auvg || true

users=`ldapsearch -x | grep "dn.*uid=.*,cn=users" |cut -f 2 -d '=' |cut -f 1 -d ','`


for user in $users
do
   if [ ! -d $dir_r/$user ]; then
      mkdir -p $dir_r/$user
      chown $user:users $dir_r/$user
   fi
   edquota -p speech -u $user
done
# -------------------------------------------------------


# -------------------------------------------------------
# copy corpus from NAS...
for file in /corpus_tar/*
do
   unzip_file=$(tar -tf $file 2>/dev/null |head -n 1)
   [ -z "$unzip_file" ] && continue;
   if [ ! -e  /share/corpus/$unzip_file ]; then 
      tar zxvf $file -C /share/corpus

      chmod 755 $(find /share/corpus/$unzip_file -type d)
      chmod 644 $(find /share/corpus/$unzip_file -type f)
   fi
done
# -------------------------------------------------------

# -------------------------------------------------------
# copy share data from NAS...
for file in /share_tar/*
do
   unzip_file=$(tar -tf $file 2>/dev/null |head -n 1)
   [ -z "$unzip_file" ] && continue;
   if [ ! -e  /share/$unzip_file ]; then
      tar zxvf $file -C /share

      chmod 755 $(find /share/$unzip_file -type d)
      chmod 644 $(find /share/$unzip_file -type f)
   fi
done
# -------------------------------------------------------

# update github using svn
su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/; git pull"
su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/kaldi/; git pull | grep up-to-date || ( 
   cd tools; make -j $threads; cd -; 
   cd src; make -j $threads ) "

# update hosts
sed -e  "s/HOST_NAME//g" $curr_dir/hosts  > $tmp || exit -1;
cp $tmp /etc/hosts || exit -1;

rm -rf $tmp

# updates bashrc
cp $curr_dir/bashrc /etc/bashrc

# update softwares
yum upgrade -y
# updates all pip packages
pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
