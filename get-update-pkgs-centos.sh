#!/bin/bash

set -x
set -e
pwd

mkdir -p /home/centos/tmp
cd /home/centos/tmp

# Updated CentOS mirrors
# Add a new repository to replace CentOS 7 mirrorlist
{
 echo "[CentOS-Base]";
 echo "name=CentOS-Base";
 echo "baseurl=http://vault.centos.org/7.9.2009/os/x86_64/";
 echo "enabled=1";
 echo "gpgcheck=0";
 echo "[CentOS-Extras]";
 echo "name=CentOS-Extras";
 echo "baseurl=https://vault.centos.org/7.9.2009/extras/x86_64/";
 echo "enabled=1";
 echo "gpgcheck=0";
} | sudo tee /etc/yum.repos.d/CentOS-Base.repo
# Clear yum cache and update system
sudo yum clean all
sudo yum update -y

# Get yumdownloader
sudo yum -y install yum-utils

#
# Get a list of OS RPMs that need to be updated, then use yumdownloader to get
# each of those RPMs, and their dependencies
#
yum makecache fast
RPMS=`repoquery --pkgnarrow=updates --nevra '*'`
for rpm in $RPMS
do
	yumdownloader --resolve $rpm
done

# Add in all of the other utilities that we want on the appliance images
yumdownloader --resolve telnet
yumdownloader --resolve nmap-ncat
yumdownloader --resolve ntp
yumdownloader --resolve zip
yumdownloader --resolve unzip
yumdownloader --resolve nano
yumdownloader --resolve sysstat
yumdownloader --resolve yum-utils
yumdownloader --resolve wget
yumdownloader --resolve python-chardet
yumdownloader --resolve cloud-init
yumdownloader --resolve open-vm-tools
yumdownloader --resolve tcpdump
yumdownloader --resolve dnsmasq
yumdownloader --resolve bind-utils
yumdownloader --resolve slirp4netns
yumdownloader --resolve fuse-overlayfs
yumdownloader --resolve container-selinux

tar -czvf ../centos7-os-rpms.tar.gz ./*.rpm

# Install the Zenoss repo so
curl -L -sO http://get.zenoss.io/yum/zenoss-repo-1-1.x86_64.rpm
sudo yum localinstall -y zenoss-repo-1-1.x86_64.rpm

sudo chmod 777 /etc/yum.repos.d
sudo cat <<EOF > /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - x86_64
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

# Use yumdownloader to get all 3rd-party dependencies for CC
yumdownloader --enablerepo=zenoss-$CC_REPO --resolve $CC_RPM --setopt=obsoletes=0

# Remove the CC package, so that we only bundling non-zenoss RPMs.
rm -f serviced* zenoss*

tar -czvf ../centos7-rpms.tar.gz ./*.rpm
