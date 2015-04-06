#!/bin/bash
 yum install -y screen cgdb htop git

 # install cgdb
 which htop 2>/dev/null >/dev/null || . ./install-cgdb.sh

 # install cuda
 which nvidia-smi
