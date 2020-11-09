sudo yum update -y
sudo yum install -y pam-devel rpm-build zlib-devel
sudo yum install -y wget
sudo yum groupinstall -y "Development tools"
sudo yum install -y openssl-devel glibc-devel krb5-devel


mkdir -p ~/rpmbuild/SOURCES
cd ~/rpmbuild/SOURCES 
wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz
wget -c http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-7.6p1.tar.gz.asc
tar zxvf openssh-7.6p1.tar.gz
cp /etc/pam.d/sshd openssh-7.6p1/contrib/redhat/sshd.pam
mv openssh-7.6p1.tar.gz{,.orig}
tar zcpf openssh-7.6p1.tar.gz openssh-7.6p1
cd 
tar zxvf ~/rpmbuild/SOURCES/openssh-7.6p1.tar.gz openssh-7.6p1/contrib/redhat/openssh.spec

# edit the specfile
cd openssh-7.6p1/contrib/redhat/
sed -i -e "s/%define no_gnome_askpass 0/%define no_gnome_askpass 1/g" openssh.spec
sed -i -e "s/%define no_x11_askpass 0/%define no_x11_askpass 1/g" openssh.spec
sed -i -e "s/BuildPreReq/BuildRequires/g" openssh.spec

rpmbuild -ba openssh.spec
cd ~/rpmbuild/RPMS/x86_64/
rpm -Uvh openssh-7.6p1-1.x86_64.rpm openssh-clients-7.6p1-1.x86_64.rpm openssh-debuginfo-7.6p1-1.x86_64.rpm openssh-server-7.6p1-1.x86_64.rpm
for file in $(ls -al /etc/ssh/ssh_host_*_key | awk '{print $NF}'); 
do
	chmod 600 $file
done
sudo systemctl restart sshd.service