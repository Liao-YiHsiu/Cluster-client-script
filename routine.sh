#!/bin/bash -ex

# routine jobs ... use crontab to execute

# check if it is already executing...

# -------------------------------------------------------
# setup home_local directory and quota for ldap users
dir_r=/home_local/
curr_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
tmp=$(mktemp)
threads=$(nproc)
threads=$((threads / 2))

PATH=$PATH:/usr/sbin

#quotacheck -avfug || true
#quotaon -auvg || true 
while true;
do
   su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/; git pull" && break || true
   sleep 10
done

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
   target=${file/share_tar/share}
   dir=$(dirname $target)
   base=$(basename $target)
   cache=$dir/.$base

   if [ -e $cache ]; then
      [ $(stat -c %Y $cache) -gt $(stat -c %Y $file) ] && continue;
   fi
   mkdir -p $dir
   chown speech:speech $dir

   unzip_file=$(tar -tf $file 2>/dev/null |head -n 1)
   [ -z "$unzip_file" ] && continue;  #incorrect file

   rm -rf $dir/$unzip_file
   cat $file | pv -L 1m | tar zxvf - -C $dir || continue;

   find $dir/$unzip_file -type d -exec chmod 755 {} \;
   find $dir/$unzip_file -type f -exec chmod 644 {} \;
   chown speech:speech -R $dir/$unzip_file

   touch $cache
done
# -------------------------------------------------------



# install all softwares
(cd $curr_dir; ./install-all.sh) || exit -1

# mount all other machines /home_local to /nfs
hostlist=$(grep 192.168.100.1 /etc/hosts | cut -f2 -d' ' | grep -v Synology)
for host in $hostlist;
do
   set +e 
   ping -c 1 $host

   # if the host is alive then try to mount
   if [ $? == 0 ]; then
      set -e
      [ -d /nfs/$host ] || mkdir -p /nfs/$host

      if [ "$(mount | grep /nfs/$host )" == "" ]; then
         if [ "$(hostname | grep -i $host)" != "" ]; then
            # bind /home_local to /nfs/$host
            mount --bind /home_local /nfs/$host
         else
            mount $host:/home_local /nfs/$host
         fi
      fi

   # if the host is dead then try to umount
   else
      set -e
      if [ "$(mount | grep /nfs/$host )" != "" ]; then
         umount -f -l /nfs/$host
      fi
   fi
done

DOM=$(date +%-d)
HOD=$(date +%-H)

# only update per month
if [ $DOM == 1 ] && [ $HOD == 4 ] ; then
   # clean /tmp that is one month ago
   day_before=$(($(date +%s) - 3600*24*14));
   for file in /tmp/*; do
      [ $(stat -c %Y $file) -gt $day_before ] && continue;
      [[ $file == *"tmux"* ]] && continue;
      # list file content before delete it!
      ls -lat $file
      rm -rf $file
   done
   # -------------------------------------------------------

   # update kaldi
   su -l speech -s /bin/bash -c "cd ~/Cluster-client-script/kaldi/; git pull | grep up-to-date || ( 
   cd tools; make clean; make -j $threads; cd -; 
   cd src; make clean && ./configure && make -j $threads depend && make -j $threads ) "
   # update softwares
   yum update -y
   yum upgrade -y
   #
   ## updates all pip packages
   pip install --upgrade setuptools pip
   #pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
   #
   ## update theano
   #pip install --upgrade --no-deps git+git://github.com/Theano/Theano.git
   ## update Keras
   pip install --upgrade Keras
fi


rm -rf $tmp
echo "routine success!"
