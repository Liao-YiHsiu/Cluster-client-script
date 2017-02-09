#!/bin/bash

curr_dir=`pwd`
tmp=$(mktemp)
trap "rm -f $tmp" EXIT

if [ $# -ne 1 ] && [ $# -ne 2 ] ; then
   echo "Usage: $0 [command] <working-dir>"
   echo
   echo "  execute [command] on all battle ship host"
   echo "  default <working-dir> is `pwd`"
   echo "  note: bash script should use copy.sh to copy to each machine."
fi

cmd=$1

if [ $# -eq 2 ]; then
   curr_dir=$2
fi

hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | grep -v Synology)

count=0
for host in $hostlist;
do
   printf "echo '=========>  $host' ;" >> $tmp
   printf "ssh -t -t $host \"cd $curr_dir; $1\"\n" >> $tmp
   count=$((count+1))
done

cat $tmp | parallel  --will-cite  -j $count --work-dir `pwd`
