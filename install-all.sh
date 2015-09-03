#!/bin/bash -ex

for script in softwares_ui/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -e $cache_file ] || exit -1
done

for script in softwares/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -e $cache_file ] || ./$script
   touch $cache_file
done

chown -R speech:speech /home_local/speech/Cluster-client-script
