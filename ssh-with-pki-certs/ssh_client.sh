#!/bin/bash

ca_url='https://13.127.53.89:8443'
fingerprint='e557419c894cbb41ae10eb171929c07e73cdfc23f6d596296bed5d86112208d4'
key_id='chiju'
ca_host_public_key='ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN2r+qa13jbgykxptEUnIeLJykhtRjmQDeKycvVgcbNr0U/3NmbE38N6zhaVkCVbRLmi/PM0bJKoaPMJdoMxDfU='
provisioner_key='pass'
password='pass'
principal='chiju'
prinncipal_2='ubuntu'

# Installing step
if ! [[ $(dpkg -l | grep step-cli) ]]
then
	curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
	sudo dpkg -i step-cli_0.12.0_amd64.deb
fi

# Install the CA cert for validating host certificates (from ~/.ssh/certs/ssh_host_key.pub` on the CA).
echo "@cert-authority *.ap-south-1.compute.amazonaws.com $ca_host_public_key" > .ssh/known_hosts

# Setting CA URL and fingerprint
step ca bootstrap -f --ca-url $ca_url --fingerprint $fingerprint

# Getting token using below command (admin command)
token=$(step ca token $key_id --principal=$principal --principal=$prinncipal_2 --ssh --password-file <(echo $provisioner_key))

# Creating client certificate
step ssh certificate $key_id id_ecdsa --token=$token --password-file <(echo $password) -f