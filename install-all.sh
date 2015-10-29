#!/bin/bash -ex
. /etc/bashrc

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

   if [ -e $cache_file ]; then
      [ $(stat -c %Y $cache_file) -gt $(stat -c %Y $script) ] && continue;
   fi

   ./$script
   touch $cache_file
done

chown -R speech:speech /home_local/speech/Cluster-client-script
