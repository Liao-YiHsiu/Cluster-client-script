#!/bin/bash -e
machine=`hostname`
tmp=$(mktemp)
trap "rm -f $tmp" EXIT

if [[ $# -gt 2 ]] || [[ $# -eq 0 ]]; then
   echo "Usage: $0 [<dir> [machine = `hostname`] ]"
   echo 
   echo "  put <dir> into /nfs/$machine/$USER/localization "
   echo "  link this file on all other machines. "
   exit -1
fi

path=$(readlink -f $1)
dirname=$(dirname $path)
basename=$(basename $path)
machine=${2:-`hostname`}

# check $machine
hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | grep -v Synology)
machine=$(echo "$hostlist" | grep -i "\b$machine\b")
if [ "$machine" == "" ]; then
   echo "Error! '$2' is not in host list (" $hostlist ")"
   exit -1
fi

# check path
if [ ! -d $path ]; then
   echo "Error! '$path' is not a directory!"
   exit -1
fi

tgt_dir="/nfs/$machine/$USER/localization"
mkdir -p $tgt_dir

# copy file into local
echo "copying data from $path to $tgt_dir"
md5=$(echo $path | md5sum | cut -d ' ' -f 1)
mv $path $tgt_dir/$md5

# build soft links
ln -sf $tgt_dir/$md5 $1
