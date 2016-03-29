#!/bin/bash -ex

yum install epel-release
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm || true

rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
yum repolist
yum --enablerepo=nux-dextop install -y ffmpeg ffmpeg-devel
