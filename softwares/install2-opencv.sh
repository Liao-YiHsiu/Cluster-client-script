#!/bin/bash -xe

wget https://github.com/Itseez/opencv/archive/3.1.0.zip
unzip 3.1.0.zip
git clone https://github.com/Itseez/opencv_contrib.git 

cd opencv-3.1.0
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..

make -j$(nproc)
make install

