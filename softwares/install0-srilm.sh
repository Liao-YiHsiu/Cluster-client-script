#!/bin/bash 

#SOURCE=/home/simpdanny/SRILM
#TARGET=.
MACHINE_TYPE=i686-m64-rhel

echo "Install SRILM 1.7.1"
echo "Scripted by simpdanny 2016/01/20"

#cp -r $SOURCE $TARGET
#SRILM=$(realpath $TARGET/SRILM)
tar -C /share -zxvf /share_tar/srilm.1.7.1
SRILM=/share/SRILM
cd $SRILM

make -j 8 SRILM=$SRILM MACHINE_TYPE=$MACHINE_TYPE

#export PATH="$PATH:$(realpath $SRILM/bin/$MACHINE_TYPE/)"

