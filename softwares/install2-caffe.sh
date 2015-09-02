#!/bin/bash -xe
## Caffe installation on CentOS by simpdanny
## Require sudo to complete this installation
YUM_OPTIONS="-y --enablerepo=epel"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

## Install location
CAFFE_PATH=/home_local/speech/Cluster-client-script
CAFFE=$CAFFE_PATH/caffe
cd $CAFFE_PATH

## Assume cuda is installed 
CUDA_PATH=/usr/local/cuda

## Require v2 cudnn for cuda 7.0
## Require v1 cudnn for cuda 6.5 or below
CUDNN_PATH=/share/cudnn-6.5-linux-x64-v2

## Install cuDNN
cp $CUDNN_PATH/cudnn.h $CUDA_PATH/include
cp $CUDNN_PATH/lib* $CUDA_PATH/lib64

## Expand repository
## RHEL/CentOS 7 64-Bit ##
cd /tmp
wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
rpm -ivh epel-release-7-5.noarch.rpm
rm -f /tmp/epel-release-7-5.noarch.rpm

## Install general dependencies
sudo yum $YUM_OPTIONS install protobuf-devel leveldb-devel snappy-devel opencv-devel boost-devel hdf5-devel


## Install more dependencies
sudo yum $YUM_OPTIONS install gflags-devel glog-devel lmdb-devel



## Install BLAS
#yum $YUM_OPTIONS install atlas-devel
sudo yum $YUM_OPTIONS install openblas-devel.x86_64

## Install Python headers
sudo yum $YUM_OPTIONS install python-devel

## Require git to clone Caffe on github
#rm -rf $CAFFE
cd $CAFFE_PATH
git clone https://github.com/BVLC/caffe.git

## Config installation by simpdanny's makefile
CONFIG=$DIR/Makefile.config
cp $CONFIG $CAFFE
cd $CAFFE

## Compile Caffe and run all test
make all
make test
make runtest

## Install python-pip
sudo yum $YUM_OPTIONS install python-pip
cd $CAFFE/python

sudo pip install --upgrade pip
## Install python-wrapper requirements
for req in $(cat requirements.txt); do sudo pip install --upgrade $req; done
sudo pip install --upgrade numpy
#easy_install -U scikit-image

## install python-wrapper
cd $CAFFE
make pycaffe

## export
export PATH=$PATH:$CAFFE/build/tools
export PYTHONPATH=$CAFFE/python:$PYTHONPATH
