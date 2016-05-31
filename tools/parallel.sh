#!/bin/bash -e

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
   echo "Execute file line by line (remove executed lines)"
   echo "Usage: $0 [Host] <filename>"
   exit 1;
fi

if [ "$#" -eq 1 ]; then
   file=$1
fi

if [ "$#" -eq 2 ]; then
   host=$1
   file=$2
fi

filename=$file
file=$(readlink -f $file)

lock_file=${file}.lock
path=${file%/*}
base=${file##*/}

if [ -z $path ]; then
   path=.
fi

vim_file=$path/.${base}.swp
tmp=$(mktemp)
tmp2=$(mktemp)

trap "rm -rf $lock_file $tmp" EXIT

tmux split-window -l 4 "watch \"cat $tmp2 && echo $host\"" || true

while true; do
   lines=$(wc -l $file | cut -f 1 -d ' ')
   if [ "$lines" -eq 0 ]; then
      break;
   fi
   line=$(
      (flock -w -1 9;

       while true; 
       do
           [ -f $vim_file ] || break; 
           echo "someone is editting $filename, check in 10 seconds latter" 1>&2;
           sleep 10;
       done

       head $file -n 1;
       tail -n +2 $file  > $tmp ;
       mv $tmp $file;

      ) 9> $lock_file
   ) 
   echo "$line" > $tmp2

   if [ -z "$host" ]; then
      bash $tmp2
   else
      ssh -t $host "cd `pwd`;`cat $tmp2`"
   fi
done
