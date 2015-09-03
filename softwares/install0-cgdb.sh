#!/bin/bash -ex
 yum -y install ncurses-devel ncurses texinfo help2man readline-devel.x86_64 readline-static.x86_64
 rm -rf cgdb
 git clone git://github.com/cgdb/cgdb.git
 cd cgdb
 ./autogen.sh
 ./configure --prefix=/usr/local
 make
 make install
 cd -
 rm -rf cgdb
