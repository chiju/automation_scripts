#!/bin/bash

pki_name='chiju'
ca_dns_name=$(curl -s ifconfig.co)
listen_address='0.0.0.0:8443'
provisioner='chiju'
password="pass"

# Installing step
if ! [[ $(dpkg -l | grep step-cli) ]]
then
	curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
	sudo dpkg -i step-cli_0.12.0_amd64.deb
fi

# Installing step-ca
if ! [[ $(dpkg -l | grep step-certificates) ]]
then
	curl -LO https://github.com/smallstep/certificates/releases/download/v0.12.0/step-certificates_0.12.0_amd64.deb
	sudo dpkg -i step-certificates_0.12.0_amd64.deb 
fi

# Initiating CA 
step ca init --ssh --name=$pki_name --dns=$ca_dns_name --address=$listen_address --provisioner=$provisioner --provisioner-password-file <(echo $password) --password-file <(echo $password)

# Adding claim line
sed -i '/"encryptedKey":/a ,"claims": { "enableSSHCA": true }' $(step path)/config/ca.json

# Starting CA server
#step-ca $(step path)/config/ca.json --password-file <(echo 'pass')
mkdir /usr/local/lib/step
echo -e "$password" > /root/.step_ca_password

cat > /etc/systemd/system/step-ca.service <<- "EOF"
[Unit]
Description=Step Certificates
Wants=basic.target
After=basic.target network.target

[Service]
WorkingDirectory=/usr/local/lib/step
ExecStart=/usr/bin/step-ca /root/.step/config/ca.json --password-file /root/.step_ca_password
KillMode=process
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Reloading systemd for the new service and starting step-ca service
systemctl daemon-reload
systemctl restart step-ca.service
systemctl status step-ca.service -l

# Printing user public key
echo "\n===="
echo -e "CA User public key $(step path)/certs/ssh_user_key.pub is"
cat $(step path)/certs/ssh_user_key.pub
echo "===="
# Printing host public key
echo -e "CA Host public key $(step path)/certs/ssh_host_key.pub is"
cat $(step path)/certs/ssh_host_key.pub
echo "===="

# Printing fringerprint and CA URL
cat $(step path)/config/defaults.json