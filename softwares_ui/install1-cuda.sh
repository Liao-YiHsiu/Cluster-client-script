#!/bin/bash -ex

#url="http://developer.download.nvidia.com/compute/cuda/.5/Prod/local_installers/cuda_7.5.18_linux.run"

pos="/home_local/speech/share/cuda_8.0.27_linux.run"

file=$(basename $pos)
tmp=$(mktemp)

rm -rf $file
cp $pos .
chmod +x $file
init 3
./$file
init 3
rm -rf $file

ldconfig /usr/local/cuda/lib64
echo "/usr/local/cuda/lib64" > $tmp
cp $tmp /etc/ld.so.conf.d/cuda-x86_64.conf

rm -rf $tmp
