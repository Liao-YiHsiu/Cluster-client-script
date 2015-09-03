#!/bin/bash -ex

url="http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run"
file=$(basename $url)
tmp=$(mktemp)

rm -rf $file
wget $url
chmod +x $file
init 3
./$file
init 5
rm -rf $file

ldconfig /usr/local/cuda/lib64
echo "/usr/local/cuda/lib64" > $tmp
cp $tmp /etc/ld.so.conf.d/cuda-x86_64.conf

rm -rf $tmp
