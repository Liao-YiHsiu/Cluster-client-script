#!/bin/bash -xe

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

rm -rf Matlab
mkdir Matlab
mount /share_tar/matlab/R2015b_glnxa64.iso Matlab

./Matlab/install -inputFile $DIR/matlab_input.txt

umount Matlab
