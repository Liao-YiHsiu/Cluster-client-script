#!/bin/bash -ex

yum -y install perl-devel
yum -y install perl-CPAN
curl -L http://cpanmin.us | perl - App::cpanminus
