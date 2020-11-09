# Bintray rpm repo with git actions

## For uploading rpms to bintray using github action
1) Add repository in bintray
--enable gpg check
2) Add package inside that repository
3) Copy folder **.github/workflows/bintray-workflow.yml** to the github repo
4) Add **Dockerfile** and **entrypoint.sh** in git repo root folder
5) Add bintray API key as **secret** in the same git repo
```
Settings >> Secrets >> Add a new secret
```

## For adding repo in server
1) add repo 
```shell
wget https://bintray.com/chiju/rpms/rpm -O bintray-chiju-rpms.repo; sudo mv bintray-chiju-rpms.repo /etc/yum.repos.d/; yum makecache
```
2) list all packages in the repo
```shell
 yum --disablerepo="*"  --enablerepo="bintray--chiju-rpms" list available
```
3) Install package
```shell
yum install openssh
```
4) execute below onliner for resolving errors while restarting ssh service
```shell
for file in $(ls -al /etc/ssh/ssh_host_*_key | awk '{print $NF}');  do chmod 600 $file; done; sudo systemctl restart sshd.service
```
