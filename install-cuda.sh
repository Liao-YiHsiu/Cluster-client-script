#!/bin/bash

[ ! -f cuda_7.0.28_linux.run ] && \
   wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run
chmod +x cuda_7.0.28_linux.run
init 3
./cuda_7.0.28_linux.run
init 5

cp /etc/bashrc tmp
echo "PATH=\$PATH:/usr/local/cuda-7.0/bin" >> tmp
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64" >> tmp
cp tmp /etc/bashrc

ldconfig /usr/local/cuda/lib64
