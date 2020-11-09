#!/bin/bash

version=7.6
username='chiju'
password=$bintray_key
repository='debs'
package='openssh'
git_repo='https://github.com/chiju/debs.git'


# creating version
curl -svvf -u $username:$password \
           -H "Content-Type: application/json" \
           -X POST https://api.bintray.com/packages/$username/$repository/$package/versions \
           --data "{\"name\": \"$version\", \"github_use_tag_release_notes\": false }"
git clone $git_repo
cd debs

#upoloading pacakges
for f in $(find -name "*.deb" -type f)
do 
	echo "Uploading $f"
	curl -svvf -X PUT -T $f -u $username:$password \
										-H "X-Bintray-Debian-Distribution:xenial" \
										-H "X-Bintray-Debian-Component:main" \
										-H "X-Bintray-Debian-Architecture:amd64" \
										https://api.bintray.com/content/$username/$repository/$package/$version/$f
done

# Publishing the version
curl -svvf -u $username:$password \
           -X POST https://api.bintray.com/content/$username/$repository/$package/$version/publish