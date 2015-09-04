#!/bin/bash -ex

# setup quota for speech
#   quotacheck -avfmug
#   quotaon -auvg
#   edquota -u speech || true
#   xfs_quota -x -c "limit -g bsoft=400G bhard=500G isoft=400G ihard=500G users" /home_local/

for script in softwares_ui/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -e $cache_file ] || ./$script
   touch $cache_file
done
