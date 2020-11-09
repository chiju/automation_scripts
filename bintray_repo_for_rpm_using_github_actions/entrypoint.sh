#!/bin/bash

version=7.6
username='chiju'
password=$bintray_key
repository='rpms'
package='openssh'
git_repo='https://github.com/chiju/rpms.git'


# creating version
curl -svvf -u $username:$password \
           -H "Content-Type: application/json" \
           -X POST https://api.bintray.com/packages/$username/$repository/$package/versions \
           --data "{\"name\": \"$version\", \"github_use_tag_release_notes\": false }"
git clone $git_repo
cd rpms

#upoloading pacakges
for f in $(find -name "*.rpm" -type f)
do 
	echo -e "\nUploading" 
	curl -v  -X PUT -T $f -u chiju:32ea322465698d89b0b2844be7d8007527516e6e \
												-H "X-Bintray-Version:$version" \
												-H "X-Bintray-Package:$package" \
												https://api.bintray.com/content/$username/$repository/
done


# Publishing the version
curl -svvf -u $username:$password \
           -X POST https://api.bintray.com/content/$username/$repository/$package/$version/publish