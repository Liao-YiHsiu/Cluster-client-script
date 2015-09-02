#!/bin/bash -ex

for script in softwares/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -f $cache_file ] || ./$script
   touch $cache_file
done
