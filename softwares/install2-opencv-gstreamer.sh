#!/bin/bash -ex

yum install -y ffmpeg-devel #Media Support
yum install -y gstreamer-plugins-base-devel #Media Support
yum install -y gstreamer-{ffmpeg,plugins-{bad,good,ugly}} 

