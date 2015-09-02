#!/bin/bash -ex

wget https://build.opensuse.org/source/home:tange/parallel/parallel_20150622.tar.gz?rev=e9dfdac7027d423e855cbead29d1d689 -O parallel.tar.gz
tar zxvf parallel.tar.gz

cd parallel*
./configure && make && sudo make install
