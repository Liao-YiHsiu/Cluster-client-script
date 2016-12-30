#!/bin/bash

url="https://get.docker.com/"
yum update
curl -fsSL $url | sh
systemctl enable docker.service
groupadd docker

