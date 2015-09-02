#!/bin/bash -ex

tmp=$(mktemp)

[ ! -f cuda_7.0.28_linux.run ] && \
   wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run
chmod +x cuda_7.0.28_linux.run
sudo init 3
sudo ./cuda_7.0.28_linux.run
sudo init 5

cp /etc/bashrc $tmp
echo "PATH=\$PATH:/usr/local/cuda-7.0/bin" >> $tmp
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64" >> $tmp
sudo cp $tmp /etc/bashrc

sudo ldconfig /usr/local/cuda/lib64
echo "/usr/local/cuda/lib64" > $tmp
sudo cp $tmp /etc/ld.so.conf.d/cuda-x86_64.conf
