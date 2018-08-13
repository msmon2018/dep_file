#!/bin/bash
PWD=$(pwd)
INSTALLER='env http_proxy= https_proxy= no_proxy= yum --disablerepo=* --enablerepo=oms_remote --nogpgcheck -y install'

yum clean all

\cp -f oms_remote.repo /etc/yum.repos.d/

setenforce 0
sed -i s/^SELINUX=.*/SELINUX=disabled/g /etc/selinux/config


#start servers
nohup ./file_server :10098  $PWD/yum_packages   &> /dev/null &
nohup ./file_server :10099  $PWD/file_packages   &> /dev/null &


$INSTALLER sshpass
$INSTALLER python2-pip
$INSTALLER net-tools
$INSTALLER gcc
$INSTALLER gcc-c++
$INSTALLER python-devel

pip install ./pip_packages/pypiserver-1.2.0-py2.py3-none-any.whl

#pip server
nohup pypi-server -p 10097 ./pip_packages  &> /dev/null &


systemctl stop firewalld
systemctl disable firewalld




netstat -nap|grep 10097|grep LISTEN
while [[ $? != 0 ]]
do
echo 'waite pip server'
sleep 1
netstat -nap|grep 10097|grep LISTEN
done

pip install ansible==2.4 -i http://localhost:10097/simple/ --trusted-host localhost:10097
#yum install -y ansible
