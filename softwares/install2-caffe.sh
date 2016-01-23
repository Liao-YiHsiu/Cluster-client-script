#!/bin/bash -xe
## Caffe installation on CentOS by simpdanny
## Require sudo to complete this installation
YUM_OPTIONS="-y --enablerepo=epel"
threads=$(nproc)

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## Install location
CAFFE_PATH=/home_local/speech/Cluster-client-script
CAFFE=$CAFFE_PATH/caffe
cd $CAFFE_PATH

## Assume cuda is installed 
CUDA_PATH=/usr/local/cuda

## Require v2 cudnn for cuda 7.0
## Require v1 cudnn for cuda 6.5 or below
CUDNN_PATH=/share/cuda

## Install cuDNN
cp $CUDNN_PATH/include/cudnn.h $CUDA_PATH/include
cp $CUDNN_PATH/lib64/lib* $CUDA_PATH/lib64

## Expand repository
## RHEL/CentOS 7 64-Bit ##
cd /tmp
rm -rf epel-release-7-5.noarch.rpm
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
rpm -ivh epel-release-7-5.noarch.rpm || true
rm -f /tmp/epel-release-7-5.noarch.rpm

## Install general dependencies
yum $YUM_OPTIONS install protobuf-devel leveldb-devel snappy-devel opencv-devel boost-devel hdf5-devel 
yum install -y libpng-devel.x86_64 freetype-devel.x86_64

## Install more dependencies
yum $YUM_OPTIONS install gflags-devel glog-devel lmdb-devel

## Install BLAS
yum $YUM_OPTIONS install atlas-devel
yum $YUM_OPTIONS install openblas-devel.x86_64

## Install jpeg
yum $YUM_OPTIONS install libjpeg-turbo-devel.x86_64

## Install Python headers
yum $YUM_OPTIONS install python-devel

## Require git to clone Caffe on github
rm -rf $CAFFE
cd $CAFFE_PATH
git clone https://github.com/BVLC/caffe.git

## Config installation by simpdanny's makefile
CONFIG=$DIR/Makefile.config
cp $CONFIG $CAFFE
cd $CAFFE

## Compile Caffe and run all test
#mkdir build
#cd build
#cmake -DBUILD_TIFF=ON -DBLAS=open .. 
sed -e 's/\(boost_filesystem.*\)$/\0 opencv_core opencv_highgui opencv_imgproc opencv_imgcodecs/' -i Makefile
export CUDA_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home_local/speech/Cluster-client-script/opencv-3.1.0/build/lib
make all -j $threads
make test -j $threads
make runtest -j $threads

## Install python-pip
yum $YUM_OPTIONS install python-pip
cd $CAFFE/python

pip install --upgrade pip
## Install python-wrapper requirements
for req in $(cat requirements.txt); do pip install --upgrade $req; done
pip install --upgrade numpy
#easy_install -U scikit-image

## install python-wrapper
cd $CAFFE
make pycaffe -j $threads

