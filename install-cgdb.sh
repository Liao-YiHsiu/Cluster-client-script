#!/bin/bash
 git clone git://github.com/cgdb/cgdb.git
 cd cgdb
 ./autogen.sh
 ./configure --prefix=/usr/local
 make
 make install
 rm -rf cgdb
