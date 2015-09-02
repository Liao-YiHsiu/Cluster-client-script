#!/bin/bash -ex
sudo yum -y install python-devel python-nose python-setuptools gcc gcc-gfortran gcc-c++ blas-devel lapack-devel atlas-devel
sudo easy_install pip
sudo pip install numpy>=1.6.1
sudo pip install scipy>=0.10.1
sudo pip install Theano
