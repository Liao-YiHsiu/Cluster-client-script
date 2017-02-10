
#!/bin/bash -ex

firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload 
systemctl enable nfs-server.service
systemctl start  nfs-server.service
echo "/home_local     192.168.100.100/24(rw,async,no_wdelay,insecure,no_root_squash,insecure_locks)" > /etc/exports
exportfs -a   
