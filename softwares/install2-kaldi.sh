#!/bin/bash -ex

tmp=$(mktemp)
threads=$(nproc)

yum install -y zlib-devel  atlas.x86_64 atlas-devel.x86_64

rm -rf kaldi
git clone https://github.com/kaldi-asr/kaldi
cd kaldi

cd tools ; make -j $threads ; cd -;
cd src   ; ./configure && make depend -j $threads && make -j $threads ; cd -;

# installing irstlm
cd tools ;
wget "http://sourceforge.net/projects/irstlm/files/latest/download" -O latest_irstlm.tgz
unzip latest_irstlm.tgz
mv irstlm*/trunk irstlm
cd irstlm; ./regenerate-makefiles.sh && ./configure --prefix=`pwd` && make -j $threads && make install
cd ../..;

chmod o+rx . -R
