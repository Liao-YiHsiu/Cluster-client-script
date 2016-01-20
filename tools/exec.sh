#!/bin/bash -e

curr_dir=`pwd`

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

hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ')

for host in $hostlist;
do
   echo "========================================"
   echo "connecting to $host"
   ssh -t $host "cd $curr_dir; $1"
   echo
done
