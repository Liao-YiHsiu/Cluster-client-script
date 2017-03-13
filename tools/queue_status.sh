#!/bin/bash
common_dir="/home/speech/.gethost/"
lock_file="$common_dir/.lock"
status_file="$common_dir/$USER"

if [[ $# -eq 0 ]]; then
   cat $lock_file | cut -d ' ' -f 1,3,4,5,6; echo; echo --$USER--; cat $status_file
else
   cat $lock_file | cut -d ' ' -f 1,3,4,5,6; echo; for file in $common_dir/*; do echo --${file##*/}--; cat $file; echo; done
fi

