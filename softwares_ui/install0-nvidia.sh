#!/bin/bash -ex

url="http://us.download.nvidia.com/XFree86/Linux-x86_64/367.35/NVIDIA-Linux-x86_64-367.35.run"	

file=$(basename $url)

rm -rf $file 
wget $url
chmod +x $file
service lightdm stop || true
init 3 || true
./$file
rm -rf $file

nvidia-smi -c 0
