#!/bin/bash

dir_r=/home_local/

set -x
quotacheck -avug
quotaon -auvg

echo "setup default user quota"
edquota -u speech

users=`ldapsearch -x | grep "dn.*uid=.*,cn=users" |cut -f 2 -d '=' |cut -f 1 -d ','`

for user in $users
do
   if [ ! -d $dir_r/$user ]; then
      mkdir -p $dir_r/$user
      chown $user:users $dir_r/$user
   fi
   edquota -p speech -u $user
done
