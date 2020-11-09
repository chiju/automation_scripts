#!/bin/bash

ca_url='https://13.127.53.89:8443'
fingerprint='e557419c894cbb41ae10eb171929c07e73cdfc23f6d596296bed5d86112208d4'
ca_user_public_key='ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJbkL3kyUtxZvLA5+r95Oixdkuiv8p8t9oEUTR6AImBMmYgzcTFcuMEuFG99YJfFC5bLEFt4ICWwA7JWYym5pSo='
provisioner='chiju'
password='pass'
#new_user='mike'

# Install `step`
if ! [[ $(dpkg -l | grep step-cli) ]]
then
	curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
	sudo dpkg -i step-cli_0.12.0_amd64.deb
fi

# Configure `step` to connect to & trust our `step-ca`
step ca bootstrap -f --ca-url  $ca_url \
                  --fingerprint $fingerprint

# Install the CA cert for validating user certificates (from ~/.ssh/certs/ssh_user_key.pub` on the CA).
echo $ca_user_public_key > $(step path)/certs/ssh_user_key.pub

# Get an SSH host certificate
export HOSTNAME="$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
export TOKEN=$(step ca token $HOSTNAME --ssh --host --provisioner $provisioner --password-file <(echo $password))
sudo step ssh certificate $HOSTNAME /etc/ssh/ssh_host_ecdsa_key.pub --host --sign --provisioner $provisioner --token $TOKEN

# Configure `sshd`
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF
# SSH CA Configuration
# The path to the CA public key for authenticatin user certificates
TrustedUserCAKeys $(step path)/certs/ssh_user_key.pub
# Path to the private key and certificate
HostKey /etc/ssh/ssh_host_ecdsa_key
HostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub
EOF
sudo service ssh restart

# Add a new user if needed
#sudo adduser --quiet --disabled-password --gecos $new_user