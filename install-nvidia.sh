#!/bin/bash

rm -f NVIDIA-Linux-x86_64-346.47.run
wget http://tw.download.nvidia.com/XFree86/Linux-x86_64/346.47/NVIDIA-Linux-x86_64-346.47.run
chmod +x NVIDIA-Linux-x86_64-346.47.run 
init 3
./NVIDIA-Linux-x86_64-346.47.run
init 5
