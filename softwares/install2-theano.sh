#!/bin/bash -ex
yum -y install python-devel python-nose python-setuptools gcc gcc-gfortran gcc-c++ blas-devel lapack-devel atlas-devel
easy_install pip
pip install --upgrade numpy
pip install --upgrade scipy
pip install --upgrade Theano
