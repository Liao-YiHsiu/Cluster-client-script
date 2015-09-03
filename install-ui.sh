#!/bin/bash -ex

for script in softwares_ui/install*;
do
   dir=$(dirname $script)
   base=$(basename $script)
   cache_file=$dir/.$base
   [ -e $cache_file ] || ./$script
   touch $cache_file
done
