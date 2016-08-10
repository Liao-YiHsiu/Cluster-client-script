#!/bin/bash -ex


url="https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.10.0rc0-cp27-none-linux_x86_64.whl"
whl=${url##*/}
wget $url 
python2.7 -m pip uninstall -y tensorflow protobuf
python2.7 -m pip install --upgrade $whl
rm $whl
