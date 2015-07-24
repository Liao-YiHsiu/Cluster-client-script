#!/bin/bash -ex

cd kaldi ;
# installing irstlm
cd tools ;
wget "http://sourceforge.net/projects/irstlm/files/latest/download" -O latest_irstlm.tgz
unzip latest_irstlm.tgz
mv irstlm*/trunk irstlm
cd irstlm; ./regenerate-makefiles.sh && ./configure --prefix=`pwd` && make -j $threads && make install
cd ../..;
