#!/bin/bash -ex
sudo yum update -y
sudo yum install -y telnet screen cgdb htop git kernel-devel kernel-headers gcc make java-1.8.0-openjdk-devel.x86_64 graphviz
sudo yum groupinstall -y "X Window System" "Desktop" "Desktop Platform"
sudo yum install -y gdm xclock
sudo yum install -y tree
sudo yum install -y flac
