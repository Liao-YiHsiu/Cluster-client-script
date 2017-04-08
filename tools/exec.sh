#!/bin/bash

curr_dir=`pwd`
tmp=$(mktemp)
trap "rm -f $tmp" EXIT

if [ $# -eq 0 ] || [ $# -gt 2 ] ; then
   echo "Usage: $0 <command> [working-dir]"
   echo
   echo "  execute <command> on all battle ship host"
   echo "  default <working-dir> is `pwd`"
   echo "  note: bash script should use copy.sh to copy to each machine."
fi

cmd=$1

if [ $# -ge 2 ]; then
   curr_dir=$(readlink -f $2)
fi

hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | grep -v Synology)

count=0
for host in $hostlist;
do
   printf "echo '=========>  %s'; " "$host" >> $tmp
   printf "ping -c 1 $host >&/dev/null;" >> $tmp
   printf "if [ \$? -eq 0 ]; then ssh %s 'cd %s; %s'; else echo '$host is not alive!'; fi;\n" "$host" "$curr_dir" "$cmd" >> $tmp
   count=$((count+1))
done
cat $tmp | parallel  --will-cite  -j $count --work-dir `pwd`
