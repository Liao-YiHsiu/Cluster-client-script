#!/bin/bash -ex

tmp=$(mktemp)

git clone https://github.com/botonchou/libdnn.git
cd libdnn/

# fix bug
sed -e "s%thrust/inner_product.h>%thrust/inner_product.h>\n#include <thrust/extrema.h>%g" include/dnn-utility.h >$tmp
cp $tmp include/dnn-utility.h

./install-sh

cp /etc/bashrc $tmp
echo "PATH=\$PATH:/home_local/speech/Cluster-client-script/libdnn/bin" >> $tmp
sudo cp $tmp /etc/bashrc
