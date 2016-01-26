#!/bin/bash -ex

# routine jobs ... use crontab to execute

# check if it is already executing...

# -------------------------------------------------------
# setup home_local directory and quota for ldap users
dir_r=/home_local/
curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
tmp=$(mktemp)
threads=$(nproc)

PATH=$PATH:/usr/sbin

#quotacheck -avfug || true
#quotaon -auvg || true

su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/; git pull"

# update hosts
# Synoloy ip = 192.168.100.97 - 192.168.100.100
host_ip=$(ifconfig | grep 192 | tr -s ' ' | cut -d ' ' -f 3 | cut -d '.' -f4)
[ $host_ip == "" ] && host_ip=0
syn_ip=$(( 100 - host_ip % 4 ))
sed -e  "s/IP/$syn_ip/g" $curr_dir/hosts  > $tmp || exit -1;
cp $tmp /etc/hosts || exit -1;

# updates bashrc
cp $curr_dir/bashrc /etc/bashrc


users=`ldapsearch -x | grep "dn.*uid=.*,cn=users" |cut -f 2 -d '=' |cut -f 1 -d ','`


for user in $users
do
   if [ ! -d $dir_r/$user ]; then
      mkdir -p $dir_r/$user
      chown $user:users $dir_r/$user
   fi

   if [ "$user" == "loach" ]; then
      continue;
   fi
   mount | grep home_local && \
   mount | grep home_local | grep xfs && \
       xfs_quota -x -c "limit -u bsoft=400G bhard=500G $user" /home_local/ || \
       edquota -p loach -u $user
done
# -------------------------------------------------------

# generate link to /share
if [ ! -L /share ]; then
   rm -rf /share
   mkdir -p $dir_r/speech/share
   ln -sf $dir_r/speech/share /share
   chown speech:speech $dir_r/speech/share
fi

# -------------------------------------------------------
# copy share data from NAS...
find /share_tar/ -iname "*.tgz" -o -iname "*.gz" | while read file; do
   unzip_file=$(tar -tf $file 2>/dev/null |head -n 1)
   [ -z "$unzip_file" ] && continue;  #incorrect file

   target=${file/share_tar/share}
   dir=$(dirname $target)
   base=$(basename $target)
   cache=$dir/.$base

   mkdir -p $dir
   chown speech:speech $dir
   if [ -e $cache ]; then
      [ $(stat -c %Y $cache) -gt $(stat -c %Y $file) ] && continue;
   fi

   rm -rf $dir/$unzip_file
   tar zxvf $file -C $dir >/dev/null 2>/dev/null || continue;

   find $dir/$unzip_file -type d -exec chmod 755 {} \;
   find $dir/$unzip_file -type f -exec chmod 644 {} \;
   chown speech:speech -R $dir/$unzip_file

   touch $cache
done
# -------------------------------------------------------

# clean /tmp that is one day before.
day_before=$(($(date +%s) - 3600*24));
for file in /tmp/*; do
   [ $(stat -c %Y $file) -gt $day_before ] && continue;
   [[ $file == *"tmux"* ]] && continue;
   rm -rf $file
done
# -------------------------------------------------------


# install all softwares
(cd $curr_dir; ./install-all.sh) || exit -1

# update kaldi
su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/kaldi/; git pull | grep up-to-date || ( 
   cd tools; make -j $threads; cd -; 
   cd src; ./configure && make -j $threads depend && make -j $threads ) "

# update softwares
#yum update -y
#yum upgrade -y
#
## updates all pip packages
#pip install --upgrade pip
#pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
#
## updates theano
#pip install --upgrade --no-deps git+git://github.com/Theano/Theano.git

rm -rf $tmp
echo "routine success!"
