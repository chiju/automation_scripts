# SSH with PKI Certificate (not with passwords/private key)

## SSH CA Server

### Downloading and installing `step` and `step-ca` packages

```shell
# Installing step
curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
sudo dpkg -i step-cli_0.12.0_amd64.deb

# Installing step-ca
curl -LO https://github.com/smallstep/certificates/releases/download/v0.12.0/step-certificates_0.12.0_amd64.deb
sudo dpkg -i step-certificates_0.12.0_amd64.deb 
```
### Initiallising CA server
#### Variables
```shell
pki_name='name_of_the_PKI'
ca_dns_name=$(curl -s ifconfig.co)
listen_address='0.0.0.0:8443'
provisioner='provisioner_name'
```
where :
`pki_name` is the name that you want to give for the public key infrastructure
`ca_dns_name` is the dns name if you are accessing via internet, if you have a domian to that name or else getting the public IP of the server using curl
`listen_address` is the listening address of CA server
`provisioner` is the name that you want to give your provisioner

### Executing command for initiallising CA server
```shell
# Initiating CA 
step ca init --ssh --name=$pki_name --dns=$ca_dns_name --address=$listen_address --provisioner=$provisioner
```
### Adding a claim line for enabling sshCA
```shell
# Adding claim line
sed -i '/"encryptedKey":/a ,"claims": { "enableSSHCA": true }' $(step path)/config/ca.json
```
### Printing user public key, host public key, fringerprint and CA URL
```shell
# Printing user public key
echo -e "CA User public key $(step path)/certs/ssh_user_key.pub is \n"
cat $(step path)/certs/ssh_user_key.pub

# Printing host public key
echo -e "CA Host public key $(step path)/certs/ssh_host_key.pub is\n"
cat $(step path)/certs/ssh_host_key.pub

# Printing fringerprint and CA URL
cat $(step path)/config/default.json
```
### Starting CA server
```shell
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
```
## SSH Host Server

Before generating certificate for host servers, need to collect below values from CA
```shell
ca_url='https://12.345.678.91:8443'
fingerprint='b3e34fccd97a01f9d2680d3b2268e5f9f76ca76ef57dc9c83c610b495936aa4f'
ca_user_public_key='<ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBJ71HgtuxX/a0HxGzVN4Z8yWifWPa92SpIQGX+4NZElB/1QKJyq1mJmcb1dM6BQCmYoNT6v/Gv+5MvJ+5QEEzI=>'
provisioner='<provisioner_name>'
password='<provisioner_password>'
```
### Installing step pacakge
```shell
# Install `step`
curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
sudo dpkg -i step-cli_0.12.0_amd64.deb
```
**Configure `step` to connect to & trust our `step-ca`**
```shell
step ca bootstrap -f --ca-url  $ca_url \
                  --fingerprint $fingerprint
 ```
### Installing the CA cert for validating user certificates (from ~/.ssh/certs/ssh_user_key.pub` on the CA).
```shell
echo $ca_user_public_key > $(step path)/certs/ssh_user_key.pub
```
### Getting an SSH host certificate
```shell
export HOSTNAME="$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)"
export TOKEN=$(step ca token $HOSTNAME --ssh --host --provisioner $provisioner --password-file <(echo $password))
sudo step ssh certificate $HOSTNAME /etc/ssh/ssh_host_ecdsa_key.pub --host --sign --provisioner $provisioner --token $TOKEN
```
### Configuring `sshd`  and restarting the same
```shell
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF
# SSH CA Configuration
# The path to the CA public key for authenticatin user certificates
TrustedUserCAKeys $(step path)/certs/ssh_user_key.pub
# Path to the private key and certificate
HostKey /etc/ssh/ssh_host_ecdsa_key
HostCertificate /etc/ssh/ssh_host_ecdsa_key-cert.pub
EOF
sudo service ssh restart
```

## User

Before generating certificate for user, need to collect below values
```shell
ca_url='https://13.126.197.57:8443'
fingerprint='b3e34fcc97a01f9d2618403b2268e5f9f76ca76ef57dc9c83c610b495936aa4f'
key_id='ubuntu@ec2-13-233-166-195.ap-south-1.compute.amazonaws.com'
ca_host_public_key='ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJgNS42bapE6ZgTYDH5v+eMKRDDwLB/W0Qmo6yIgS6evXN44N5/hMNuMqzCjT/ArYxuNuoxIGtBcDYvWVdhOxfM='
provisioner_key='<provisioner_password>'
password='<user_private_key_password>'
```

### Installing step
```shell
curl -LO https://github.com/smallstep/cli/releases/download/v0.12.0/step-cli_0.12.0_amd64.deb
sudo dpkg -i step-cli_0.12.0_amd64.deb
```
### Install the CA cert for validating host certificates (from ~/.ssh/certs/ssh_host_key.pub` on the CA).
```shell
echo "@cert-authority *.ap-south-1.compute.amazonaws.com $ca_host_public_key" > .ssh/known_hosts
```
### Setting CA URL and fingerprint
```shell
step ca bootstrap -f --ca-url $ca_url --fingerprint $fingerprint
```
### Get token using below command
```shell
token=$(step ca token $key_id --principal=ubuntu --ssh --password-file <(echo $provisioner_key))
```
### Creating client certificate
```shell
step ssh certificate $key_id id_ecdsa --token=$token --password-file <(echo $password)
```

## For revoking access

From the host server, execute below commands
```shell
ssh-keygen -k -f /etc/ssh/revoked_keys -s .step/certs/ssh_user_key.pub
echo "RevokedKeys /etc/ssh/revoked_keys" >> /etc/ssh/sshd_config
service sshd restart
```
Adding client key that you want to revoke access
```shell
echo "ubuntu@ec2-13-233-166-195.ap-south-1.compute.amazonaws.com" >> /etc/ssh/revoked_keys
```

## For Blocking access to some of the users

By default, OpenSSH servers will allow to connect if the username we're connecting as is listed as a principal in our certificate 
However, if an  `AuthorizedPrincipalsFile`  is configured, this default isn't used. The  `AuthorizedPrincipalsFile`  must include  all  principals that are allowed to SSH as a particular user.

If I configure  `sshd`  to use an  `AuthorizedPrincipalsFile`:

```shell
# echo "AuthorizedPrincipalsFile .ssh/authorized_principals" >> /etc/ssh/sshd_config
# service sshd restart
```
Then create an  _empty_  `AuthorizedPrincipalsFile`  for the user "mike":
```
# touch ~mike/.ssh/authorized_principals
```
I can no longer SSH as "mike", even if I have a valid certificate:
```
$ ssh ec2-54-82-246-45.compute-1.amazonaws.com
mike@ec2-54-82-246-45.compute-1.amazonaws.com: Permission denied (publickey).
```
If I add "mike" to the  `AuthorizedPrincipalsFile`, access is allowed again:
```
# echo "mike" >> ~mike/.ssh/authorized_principals
```
```
$ ssh ec2-54-82-246-45.compute-1.amazonaws.com
Welcome to Ubuntu 18.04.2 LTS (GNU/Linux 4.15.0-1044-aws x86_64)
mike@ip-172-31-68-208:~$
```

## For token and certificate expirations
Command
`step ca token $key_id --principal=$principal --principal=$prinncipal_2 --ssh --password-file <(echo $provisioner_key))`

Below options can be used for setting token expiration time or certificate expiration times
```
--cert-not-after=time|duration
          The time|duration when the certificate validity period ends. If a time
          is used it is expected to be in RFC 3339 format. If a duration is used,
          it is a sequence of decimal numbers, each with optional fraction and a
          unit suffix, such as "300ms", "-1.5h" or "2h45m". Valid time units are
          "ns", "us" (or "µs"), "ms", "s", "m", "h".

--cert-not-before=time|duration
          The time|duration when the certificate validity period starts. If a
          time is used it is expected to be in RFC 3339 format. If a duration is
          used, it is a sequence of decimal numbers, each with optional fraction
          and a unit suffix, such as "300ms", "-1.5h" or "2h45m". Valid time
          units are "ns", "us" (or "µs"), "ms", "s", "m", "h".

--not-before=time|duration
          The time|duration set in the NotBefore (nbf) property of the token. If
          a time is used it is expected to be in RFC 3339 format. If a duration
          is used, it is a sequence of decimal numbers, each with optional
          fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m". Valid
          time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".

--not-after=time|duration
          The time|duration set in the Expiration (exp) property of the token.
          If a time is used it is expected to be in RFC 3339 format. If a
          duration is used, it is a sequence of decimal numbers, each with
          optional fraction and a unit suffix, such as "300ms", "-1.5h" or
          "2h45m". Valid time units are "ns", "us" (or "µs"), "ms", "s", "m",
          "h".
```