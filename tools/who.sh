#!/bin/bash

if [[ $# -ne 1 ]]; then
   echo "Usage: $0 [user_name] "
   echo 
   echo "  Lookup the <user_name> in database, return chinese name"
   exit -1
fi

user=$1

echo `ldapsearch -x | grep "$user"  -C 1 | grep gecos | cut -d ' ' -f2 | base64 --decode`
