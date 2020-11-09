# Bintray debs repo with git actions

## For uploading rpms to bintray using github action
1) Add repository in bintray 
--enable Trivial index
--enable gpg signing

2) Add package to that repository
--BSD liscence
--version control-https://github.com/chiju/debs

3) Copy folder **.github/workflows/bintray-workflow.yml** to the github repo

4) Add **Dockerfile** and **entrypoint.sh** in git repo root folder

5) Add bintray API key as **secret** in the same git repo
```
Settings >> Secrets >> Add a new secret
```

## For adding repo in server

1) For adding repo in the server and bintray key
```shell
echo "deb https://dl.bintray.com/chiju/debs /" | sudo tee -a /etc/apt/sources.list; wget https://bintray.com/user/downloadSubjectPublicKey?username=bintray -O bintray-key; apt-key add bintray-key
```

2) For listing packages
```shell
apt-get update; grep ^Package /var/lib/apt/lists/dl.bintray.com*_Packages | awk '{print $2}' | sort -u
```
3) For installing all packages in from that repo
```shell
for i in $(grep ^Package /var/lib/apt/lists/dl.bintray.com*_Packages | awk '{print $2}' | sort -u); do apt-get install $i -y --allow-unauthenticated; done
```