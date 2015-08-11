#!/bin/bash -xe
# Torch7 installation by wyc2010

TORCH_PATH=/home_local/speech/Cluster-client-script/torch

# dependencies
curl -s https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash

# torch7
# it will ask you automatically setting .bashrc, just type "no"
if [[ ! -d ${TORCH_PATH} ]]; then git clone https://github.com/torch/distro.git ${TORCH_PATH} --recursive;fi
cd ${TORCH_PATH}; ./install.sh

# env variable
#sudo sed -i '$a . '${TORCH_PATH}'/install/bin/torch-activate' /etc/bashrc  # doesn't work ???
tmp=$(mktemp)
if ! grep torch-activate /etc/bashrc; then
        cp /etc/bashrc $tmp
        echo ". ${TORCH_PATH}/install/bin/torch-activate" >> $tmp
        sudo cp $tmp /etc/bashrc
fi

# To uninstall
# rm -rf ${TORCH_PATH}/torch

