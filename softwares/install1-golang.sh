#!/bin/bash 

url="https://storage.googleapis.com/golang/go1.7.4.linux-amd64.tar.gz"
file=$(basename $url)
echo $file
tmp=$(mktemp -d)

cd $tmp 
curl -LO $url

sum=`sha256sum go1.7*.tar.gz | cut -f 1 -d ' '`
echo $sum

if [ $sum == "47fda42e46b4c3ec93fa5d4d4cc6a748aa3f9411a2a2b7e08e3a6d80d753ec8b" ] 
then 
echo "sha256 is right"
fi

tar -C /usr/local -zxvf $file
cd ..
rm -rf $tmp


