#!/bin/bash -ex
yum -y install ntp
chkconfig ntpd on
ntpdate pool.ntp.org
service ntpd start
