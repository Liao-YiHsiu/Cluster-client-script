#!/bin/bash 

url="https://github.com/openai/universe.git"

git clone $url
cd universe
pip2 install -e .
pip3 install -e .
cd ../

