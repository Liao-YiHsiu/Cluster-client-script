#!/bin/bash -ex

rm -rf parallel.tar.bz2
wget http://ftp.gnu.org/gnu/parallel/parallel-20160122.tar.bz2 -O parallel.tar.bz2
tar -xjf parallel.tar.bz2

cd parallel*
./configure && make && make install
