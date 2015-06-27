#!/bin/bash

url="http://us.download.nvidia.com/XFree86/Linux-x86_64/352.21/NVIDIA-Linux-x86_64-352.21.run"

file=$(basename $url)

[ ! -f $file ] && \
   wget $url
chmod +x $file
service lightdm stop
init 3
./$file
init 5
