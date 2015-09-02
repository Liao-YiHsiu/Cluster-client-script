#!/bin/bash -ex

url="http://us.download.nvidia.com/XFree86/Linux-x86_64/352.21/NVIDIA-Linux-x86_64-352.21.run"

file=$(basename $url)

[ ! -f $file ] && \
   wget $url
chmod +x $file
service lightdm stop || true
init 3 || true
./$file
init 5
