# Upating repos
sudo apt-get update

# Downloading and extracting source packages

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh_7.6p1-4.dsc
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh_7.6p1.orig.tar.gz
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh_7.6p1.orig.tar.gz.asc
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssh/openssh_7.6p1-4.debian.tar.xz
tar -zxvf openssh_7.6p1.orig.tar.gz
tar -xvf openssh_7.6p1-4.debian.tar.xz

# Install build dependency packages
sudo apt-get install -t xenial-backports devscripts autotools-dev debhelper dh-autoreconf dh-exec dh-systemd libaudit-dev libedit-dev libgtk-3-dev libkrb5-dev libpam-dev libselinux1-dev libssl-dev libwrap0-dev zlib1g-dev libsystemd-dev -y
sudo apt-get install build-essential fakeroot dpkg-dev

# Building packages
dpkg-source -x openssh_7.6p1-4.dsc
cd openssh-7.6p1/
dpkg-buildpackage -rfakeroot -b

# Now package would have been succesfully built on root directory (cd ../)
cd ..
ls -ltr *.deb

# Stoping ssh
sudo systemctl stop ssh

# Installing
sudo dpkg -i --force-confold  openssh-client_7.6p1-4_amd64.deb openssh-server_7.6p1-4_amd64.deb openssh-sftp-server_7.6p1-4_amd64.deb

# Checking the version
ssh -V