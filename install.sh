#!/bin/bash
 yum update -y
 yum install -y screen cgdb htop git kernel-devel kernel-headers gcc make

 # install cgdb
 which htop       2>/dev/null >/dev/null || ./install-cgdb.sh

 # install nvidia-driver
 which nvidia-smi 2>/dev/null >/dev/null || ./install-nvidia.sh

 # install cuda
 which nvcc       2>/dev/null >/dev/null || ./install-cuda.sh

 # install kaldi
 which copy-feats 2>/dev/null >/dev/null || ./install-kaldi.sh
