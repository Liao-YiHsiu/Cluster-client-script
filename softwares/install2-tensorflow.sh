#!/bin/bash -ex

url="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.11.0rc1-cp27-none-linux_x86_64.whl"
whl=${url##*/}
wget $url 
#python2.7 -m pip uninstall -y tensorflow protobuf || true
python2.7 -m pip install --upgrade $whl
rm $whl
