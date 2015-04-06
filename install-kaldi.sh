#!/bin/bash

svn co https://svn.code.sf.net/p/kaldi/code/trunk kaldi-trunk
cd kaldi-trunk
svn update

cd tools ; make -j 12 ; cd -;
cd src   ; ./configure && make depend -j 12 && make -j 12 ; cd -;

now_dir=`pwd`

cp /etc/bashrc tmp
echo "PATH=$PATH:$now_dir/src/bin:$now_dir/tools/openfst/bin:$now_dir/tools/irstlm/bin/:$now_dir/src/fstbin/:$now_dir/src/gmmbin/:$now_dir/src/featbin/:$now_dir/src/lm/:$now_dir/src/sgmmbin/:$now_dir/src/sgmm2bin/:$now_dir/src/fgmmbin/:$now_dir/src/latbin/:$now_dir/src/nnetbin:$now_dir/src/nnet2bin/:$now_dir/src/kwsbin" >> tmp
cp tmp /etc/bashrc
