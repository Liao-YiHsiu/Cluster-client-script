#!/bin/bash -ex

for script in softwares/install*;
do
   ./$script
done
