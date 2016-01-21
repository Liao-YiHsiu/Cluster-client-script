#!/bin/bash


if [[ $# -ne 1 ]]; then
   echo "Usage: $0 [filepath] "
   echo 
   echo "  copy /home_local/$USER/filepath Data into different hosts"
   echo "  possible choices: $(ls /home_local/$USER | tr '\n' ' ')"
   exit -1
fi

path=$1

hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | sed -e "s/$HOSTNAME//g")

for host in $hostlist;
do

    echo "rsync -azP /home_local/$USER/$path/ $host:/home_local/$USER/$path"
    ssh $host "mkdir -p /home_local/$USER/$path"
    rsync -azP /home_local/$USER/$path/ $host:/home_local/$USER/$path &

done

