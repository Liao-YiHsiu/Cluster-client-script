#!/bin/bash -ex

apt-get install libcupti-dev

url="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.0.0-cp27-none-linux_x86_64.whl"
whl=${url##*/}
wget $url 
#python2.7 -m pip uninstall -y tensorflow protobuf || true
python2.7 -m pip install --upgrade $whl
rm $whl

url="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.0.0-cp34-cp34m-linux_x86_64.whl"
whl=${url##*/}
wget $url
python3.4 -m pip install --upgrade $whl

rm $whl
