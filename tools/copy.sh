#!/bin/bash -e

if [[ $# -ne 1 ]]; then
   echo "Usage: $0 [filepath] "
   echo 
   echo "  copy /home_local/$USER/filepath Data into different hosts"
   echo "  possible choices: $(ls /home_local/$USER | tr '\n' ' ')"
   exit -1
fi

path=$1

hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | sed -e "s/$HOSTNAME//g")
tmpdir=$(mktemp -d)
cmd="tar zcf - /home_local/$USER/$path "

trap "rm -rf $tmpdir; exit -1" EXIT

for host in $hostlist;
do
   mkfifo $tmpdir/$host
   ssh $host "rm -rf /home_local/$USER/$path"
   cat $tmpdir/$host | ssh $host "tar zxf - -C /" &
   cmd="$cmd | tee $tmpdir/$host "
   echo "copying to $host"
done

cmd="$cmd > /dev/null"
eval $cmd


