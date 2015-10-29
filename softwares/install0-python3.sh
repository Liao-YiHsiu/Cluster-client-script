#!/bin/bash -ex
yum -y install python34.x86_64
wget https://bootstrap.pypa.io/get-pip.py;
chmod +x ./get-pip.py;
python3.4 get-pip.py
