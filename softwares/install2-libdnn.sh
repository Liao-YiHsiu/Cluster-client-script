#!/bin/bash -ex

tmp=$(mktemp)

rm -rf libdnn
git clone https://github.com/botonchou/libdnn.git
cd libdnn/

# fix bug
sed -e "s%thrust/inner_product.h>%thrust/inner_product.h>\n#include <thrust/extrema.h>%g" include/dnn-utility.h >$tmp
cp $tmp include/dnn-utility.h

./install-sh
