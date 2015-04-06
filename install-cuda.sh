#!/bin/bash

wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run
chmod +x cuda_7.0.28_linux.run
init 3
./cuda_7.0.28_linux.run
init 5
