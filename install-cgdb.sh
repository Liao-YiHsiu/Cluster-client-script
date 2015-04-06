#!/bin/bash
 yum -y install ncurses-devel ncurses texinfo help2man readline-devel.x86_64 readline-static.x86_64
 git clone git://github.com/cgdb/cgdb.git
 cd cgdb
 ./autogen.sh
 ./configure --prefix=/usr/local
 make
 make install
 rm -rf cgdb
