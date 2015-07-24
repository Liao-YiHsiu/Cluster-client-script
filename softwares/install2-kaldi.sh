#!/bin/bash -ex

tmp=$(mktemp)
threads=$(nproc)

sudo yum install -y zlib-devel  atlas.x86_64 atlas-devel.x86_64

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

now_dir=`pwd`

cp /etc/bashrc $tmp
echo "PATH=\$PATH:$now_dir/src/bin:$now_dir/tools/openfst/bin:$now_dir/tools/irstlm/bin/:$now_dir/src/fstbin/:$now_dir/src/gmmbin/:$now_dir/src/featbin/:$now_dir/src/lm/:$now_dir/src/sgmmbin/:$now_dir/src/sgmm2bin/:$now_dir/src/fgmmbin/:$now_dir/src/latbin/:$now_dir/src/nnetbin:$now_dir/src/nnet2bin/:$now_dir/src/kwsbin" >> $tmp
sudo cp $tmp /etc/bashrc
