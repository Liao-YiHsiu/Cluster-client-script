#!/bin/bash -ex

# setup quota for speech
   quotacheck -avfmug
   quotaon -auvg
   edquota -u speech || true

for script in softwares_ui/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -e $cache_file ] || ./$script
   touch $cache_file
done
