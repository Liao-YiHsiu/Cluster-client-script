#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir Matlab
mount /share_tar/matlab/R2015b_glnxa64.iso Matlab

./Matlab/install -inputFile $DIR/installer_input.txt

umount Matlab
echo 'PATH=$PATH:/usr/local/MATLAB/R2015b/bin' >> ~/.bashrc
