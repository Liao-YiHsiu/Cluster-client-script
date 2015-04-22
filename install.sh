#!/bin/bash
 yum update -y
 yum install -y telnet screen cgdb htop git kernel-devel kernel-headers gcc make java-1.8.0-openjdk-devel.x86_64
 yum groupinstall -y "X Window System" "Desktop" "Desktop Platform"
 yum install -y gdm xclock
 yum install -y tree
