# Icinga2-Three Levels with Master, Satellites, and Clients

Icinga2 for three level setup including master, satellites and clients

## Master setup

1) Install icinga2 and icingaweb2 (ansible roles are there).
2) Execute below command for master setup.
```shell
[root@icinga2-satellite1 ~]#icinga2 node wizard
```
3)  Provide the values as given below.
```shell
[root@icinga2-master1.localdomain /]# icinga2 node wizard

Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is a satellite/client setup ('n' installs a master setup) [Y/n]: n

Starting the Master setup routine...

Please specify the common name (CN) [icinga2-master1.localdomain]: icinga2-master1.localdomain
Reconfiguring Icinga...
Checking for existing certificates for common name 'icinga2-master1.localdomain'...
Certificates not yet generated. Running 'api setup' now.
Generating master configuration for Icinga 2.
Enabling feature api. Make sure to restart Icinga 2 for these changes to take effect.

Master zone name [master]:

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: N

Please specify the API bind host/port (optional):
Bind Host []:
Bind Port []:

Do you want to disable the inclusion of the conf.d directory [Y/n]:n
Disabling the inclusion of the conf.d directory...
Checking if the api-users.conf file exists...

Done.

Now restart your Icinga 2 daemon to finish the installation!
```
3) Restart icinga2 service.
```shell
systemctl restart icinga2.service
```
## Satellite setup

1) Execute the below commands for installing icinga and required plugins.
```shell
[root@icinga2-master1.localdomain /]#yum -y update
[root@icinga2-master1.localdomain /]#yum install -y https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm -y 
[root@icinga2-master1.localdomain /]#yum install -y epel-release 
[root@icinga2-master1.localdomain /]#yum install -y bash-completion vim icinga2 nagios-plugins-all 
[root@icinga2-master1.localdomain /]#systemctl enable icinga2
[root@icinga2-master1.localdomain /]#systemctl start icinga2
```
2) Execute below command for satelite setup
```shell
[root@icinga2-satellite1 ~]#icinga2 node wizard
```
3)  Provide the values as given below
```shell
[root@icinga2-satellite1 ~]# icinga2 node wizard 
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is a satellite/client setup ('n' installs a master setup) [Y/n]: Y

Starting the Client/Satellite setup routine...

Please specify the common name (CN) [icinga2-satellite1.localdomain]: 

Please specify the parent endpoint(s) (master or satellite) where this node should connect to:
Master/Satellite Common Name (CN from your master/satellite node): 13.232.251.204

Do you want to establish a connection to the parent node from this node? [Y/n]: Y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): ^C
[root@icinga2-satellite1 ~]# icinga2 node wizard 
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is a satellite/client setup ('n' installs a master setup) [Y/n]: Y

Starting the Client/Satellite setup routine...

Please specify the common name (CN) [icinga2-satellite1.localdomain]: 

Please specify the parent endpoint(s) (master or satellite) where this node should connect to:
Master/Satellite Common Name (CN from your master/satellite node): icinga2-master1.localdomain

Do you want to establish a connection to the parent node from this node? [Y/n]: Y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): 13.232.251.204
Master/Satellite endpoint port [5665]: 

Add more master/satellite endpoints? [y/N]: N
Parent certificate information:

 Subject:     CN = icinga2-master1.localdomain
 Issuer:      CN = Icinga CA
 Valid From:  Jul 24 05:30:09 2019 GMT
 Valid Until: Jul 20 05:30:09 2034 GMT
 Fingerprint: 04 9C E8 DE 3E 27 3D 78 2B 14 DF 49 1E 17 1E C0 D8 40 53 62 

Is this information correct? [y/N]: y

Please specify the request ticket generated on your Icinga 2 master (optional).
 (Hint: # icinga2 pki ticket --cn 'icinga2-satellite1.localdomain'): a7724a7bfa15e118c3bd040d9ec3b2a3622bd780
Please specify the API bind host/port (optional):
Bind Host []: 
Bind Port []: 

Accept config from parent node? [y/N]: y
Accept commands from parent node? [y/N]: y

Reconfiguring Icinga...
Disabling feature notification. Make sure to restart Icinga 2 for these changes to take effect.
Enabling feature api. Make sure to restart Icinga 2 for these changes to take effect.

Local zone name [icinga2-satellite1.localdomain]: satellite
Parent zone name [master]: 

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: N

Do you want to disable the inclusion of the conf.d directory [Y/n]: n

Done.

Now restart your Icinga 2 daemon to finish the installation!
```
3) Restart icinga2 service
```shell
systemctl restart icinga2.service
```
4) Add zone and endpoint objects to Master's /etc/icinga2/zones.conf file
```shell
object Endpoint "icinga2-satellite1.localdomain" {
	host = "13.235.83.254"
}

object Zone "satellite" {
	endpoints = [ "icinga2-satellite1.localdomain" ]
	parent = "master"
}
```
5) Make directory for satelite zone in Master.
```shell
[root@icinga2-master1.localdomain /]#mkdir /etc/icinga2/zones.d/satellite
```
6) Add host definition in the hostfile inside /etc/icinga2/zones.d/satellite directory.
```shell
[root@icinga2-master1.localdomain /]#vim /etc/icinga2/zones.d/satellite/icinga2-satellite1.localdomain.conf
```
```shell
[root@icinga2-master1.localdomain /]#cat /etc/icinga2/zones.d/satellite/icinga2-satellite1.localdomain.conf
object Host "13.235.83.254" {
  /* Import the default host template defined in `templates.conf`. */
  import "generic-host"

  /* Specify the address attributes for checks e.g. `ssh` or `http`. */
  address = "13.235.83.254"
  address6 = "::1"

  /* Set custom attribute `os` for hostgroup assignment in `groups.conf`. */
  vars.os = "Linux"

  /* Define http vhost attributes for service apply rules in `services.conf`. */
  vars.http_vhosts["http"] = {
    http_uri = "/"
  }
  /* Uncomment if you've sucessfully installed Icinga Web 2. */
  //vars.http_vhosts["Icinga Web 2"] = {
  //  http_uri = "/icingaweb2"
  //}

  /* Define disks and attributes for service apply rules in `services.conf`. */
  vars.disks["disk"] = {
    /* No parameters. */
  }
  vars.disks["disk /"] = {
    disk_partitions = "/"
  }

  /* Define notification mail attributes for notification apply rules in `notifications.conf`. */
  vars.notification["mail"] = {
    /* The UserGroup `icingaadmins` is defined in `users.conf`. */
    groups = [ "icingaadmins" ]
  }
}
```
7) Update ownership to **icinga** user and **icinga** group.
```shell
[root@icinga2-master1.localdomain /]#chown -R icinga:icinga /etc/icinga2/zones.d/
```
8) Restart icinga2 service
```shell
systemctl restart icinga2.service
```
## Client setup

1) Execute the below commands for installing icinga and required plugins.
```shell
[root@icinga2-master1.localdomain /]#yum -y update
[root@icinga2-master1.localdomain /]#yum install -y https://packages.icinga.com/epel/icinga-rpm-release-7-latest.noarch.rpm -y 
[root@icinga2-master1.localdomain /]#yum install -y epel-release 
[root@icinga2-master1.localdomain /]#yum install -y bash-completion vim icinga2 nagios-plugins-all 
[root@icinga2-master1.localdomain /]#systemctl enable icinga2
[root@icinga2-master1.localdomain /]#systemctl start icinga2
```
2) Execute below command for client setup 
```shell
[root@icinga2-satellite1 ~]#icinga2 node wizard
```
3)  Provide the values as given below
```shell
[root@icinga2-client1 ~]# icinga2 node wizard 
Welcome to the Icinga 2 Setup Wizard!

We will guide you through all required configuration details.

Please specify if this is a satellite/client setup ('n' installs a master setup) [Y/n]: Y

Starting the Client/Satellite setup routine...

Please specify the common name (CN) [icinga2-client1.localdomain]: 

Please specify the parent endpoint(s) (master or satellite) where this node should connect to:
Master/Satellite Common Name (CN from your master/satellite node): icinga2-satellite1.localdomain

Do you want to establish a connection to the parent node from this node? [Y/n]: Y
Please specify the master/satellite connection information:
Master/Satellite endpoint host (IP address or FQDN): 13.235.83.254
Master/Satellite endpoint port [5665]: 

Add more master/satellite endpoints? [y/N]: N
Parent certificate information:

 Subject:     CN = icinga2-satellite1.localdomain
 Issuer:      CN = Icinga CA
 Valid From:  Jul 24 07:14:09 2019 GMT
 Valid Until: Jul 20 07:14:09 2034 GMT
 Fingerprint: C2 D6 B2 BF 13 C3 44 36 9B 6B E0 A4 15 E3 7B 06 9F 3D 60 E8 

Is this information correct? [y/N]: y

Please specify the request ticket generated on your Icinga 2 master (optional).
 (Hint: # icinga2 pki ticket --cn 'icinga2-client1.localdomain'): 1c523cc6c446eb17f377d8f8b04c26870d26780c
Please specify the API bind host/port (optional):
Bind Host []: 
Bind Port []: 

Accept config from parent node? [y/N]: y
Accept commands from parent node? [y/N]: y

Reconfiguring Icinga...
Disabling feature notification. Make sure to restart Icinga 2 for these changes to take effect.
Enabling feature api. Make sure to restart Icinga 2 for these changes to take effect.

Local zone name [icinga2-client1.localdomain]: client 
Parent zone name [master]: satellite

Default global zones: global-templates director-global
Do you want to specify additional global zones? [y/N]: N

Do you want to disable the inclusion of the conf.d directory [Y/n]: n

Done.

Now restart your Icinga 2 daemon to finish the installation!
```
3) Restart icinga2 service
```shell
systemctl restart icinga2.service
```
4) Add zone and endpoint objects to Master's /etc/icinga2/zones.conf file
```shell
object Endpoint "icinga2-client1.localdomain" {
        host = "13.235.49.239"
}

object Zone "client" {
        endpoints = [ "icinga2-client1.localdomain" ]
        parent = "satellite"
}
```
5) Make directory for client zone under satellite folder in Master.
```shell
[root@icinga2-master1.localdomain /]#mkdir /etc/icinga2/zones.d/satellite/client
```
6) Add host definition in the hostfile inside **/etc/icinga2/zones.d/satellite/cleint** directory.
```shell
[root@icinga2-master1 ~]# vim /etc/icinga2/zones.d/satellite/client/icinga2-client1.localdomain.conf
```
```shell
object Host "icinga2-client1.localdomain" {
  /* Import the default host template defined in `templates.conf`. */
  import "generic-host"

  /* Specify the address attributes for checks e.g. `ssh` or `http`. */
  address = "13.235.49.239"
  address6 = "::1"

  /* Set custom attribute `os` for hostgroup assignment in `groups.conf`. */
  vars.os = "Linux"

  /* Define http vhost attributes for service apply rules in `services.conf`. */
  vars.http_vhosts["http"] = {
    http_uri = "/"
  }
  /* Uncomment if you've sucessfully installed Icinga Web 2. */
  //vars.http_vhosts["Icinga Web 2"] = {
  //  http_uri = "/icingaweb2"
  //}

  /* Define disks and attributes for service apply rules in `services.conf`. */
  vars.disks["disk"] = {
    /* No parameters. */
  }
  vars.disks["disk /"] = {
    disk_partitions = "/"
  }

  /* Define notification mail attributes for notification apply rules in `notifications.conf`. */
  vars.notification["mail"] = {
    /* The UserGroup `icingaadmins` is defined in `users.conf`. */
    groups = [ "icingaadmins" ]
  }
}
```
7) Update ownership to **icinga** user and **icinga** group.
```shell
[root@icinga2-master1.localdomain /]#chown -R icinga:icinga /etc/icinga2/zones.d/
```
8) Restart icinga2 service
```shell
systemctl restart icinga2.service
```
## Satellite2 and client2 setups

Repeat the same setup procedure for satelite2 and client2, make sure to change IP and CN name of satelite and client. 

## 	Directory structure in Master
```shell
[root@icinga2-master1 zones.d]# tree /etc/icinga2/zones.d/
/etc/icinga2/zones.d/
|-- README
|-- satellite
|   |-- client
|   |   `-- icinga2-client1.localdomain.conf
|   `-- icinga2-satellite1.localdomain.conf
`-- satellite2
    |-- client2
    |   `-- icinga2-client2.localdomain.conf
    `-- icinga2-satellite2.localdomain.conf

4 directories, 5 files
```

## Final conf files

### Master
#### /etc/icinga2/zones.conf
```shell
/*
 * Generated by Icinga 2 node setup commands
 * on 2019-07-24 06:47:42 +0000
 */

object Endpoint "icinga2-master1.localdomain" {
}

object Zone "master" {
	endpoints = [ "icinga2-master1.localdomain" ]
}

object Endpoint "icinga2-satellite1.localdomain" {
	host = "13.235.83.254"
}

object Zone "satellite" {
	endpoints = [ "icinga2-satellite1.localdomain" ]
	parent = "master"
}

object Endpoint "icinga2-satellite2.localdomain" {
	host = "13.233.244.75"
}

object Zone "satellite2" {
	endpoints = [ "icinga2-satellite2.localdomain" ]
	parent = "master"
}

object Endpoint "icinga2-client1.localdomain" {
        host = "13.235.49.239"
}

object Zone "client" {
        endpoints = [ "icinga2-client1.localdomain" ]
        parent = "satellite"
}

object Endpoint "icinga2-client2.localdomain" {
	host = "35.154.127.97"
}

object Zone "client2" {
	endpoints = [ "icinga2-client2.localdomain" ]
	parent = "satellite2"
}

object Zone "global-templates" {
	global = true
}

object Zone "director-global" {
	global = true
}
```
#### /etc/icinga2/zones.d/satellite/icinga2-satellite1.localdomain.conf 

```shell
object Host "13.235.83.254" {
  /* Import the default host template defined in `templates.conf`. */
  import "generic-host"

  /* Specify the address attributes for checks e.g. `ssh` or `http`. */
  address = "13.235.83.254"
  address6 = "::1"

  /* Set custom attribute `os` for hostgroup assignment in `groups.conf`. */
  vars.os = "Linux"

  /* Define http vhost attributes for service apply rules in `services.conf`. */
  vars.http_vhosts["http"] = {
    http_uri = "/"
  }
  /* Uncomment if you've sucessfully installed Icinga Web 2. */
  //vars.http_vhosts["Icinga Web 2"] = {
  //  http_uri = "/icingaweb2"
  //}

  /* Define disks and attributes for service apply rules in `services.conf`. */
  vars.disks["disk"] = {
    /* No parameters. */
  }
  vars.disks["disk /"] = {
    disk_partitions = "/"
  }

  /* Define notification mail attributes for notification apply rules in `notifications.conf`. */
  vars.notification["mail"] = {
    /* The UserGroup `icingaadmins` is defined in `users.conf`. */
    groups = [ "icingaadmins" ]
  }
}
```
#### /etc/icinga2/zones.d/satellite/client/icinga2-client1.localdomain.conf
```shell
object Host "icinga2-client1.localdomain" {
  /* Import the default host template defined in `templates.conf`. */
  import "generic-host"

  /* Specify the address attributes for checks e.g. `ssh` or `http`. */
  address = "13.235.49.239"
  address6 = "::1"

  /* Set custom attribute `os` for hostgroup assignment in `groups.conf`. */
  vars.os = "Linux"

  /* Define http vhost attributes for service apply rules in `services.conf`. */
  vars.http_vhosts["http"] = {
    http_uri = "/"
  }
  /* Uncomment if you've sucessfully installed Icinga Web 2. */
  //vars.http_vhosts["Icinga Web 2"] = {
  //  http_uri = "/icingaweb2"
  //}

  /* Define disks and attributes for service apply rules in `services.conf`. */
  vars.disks["disk"] = {
    /* No parameters. */
  }
  vars.disks["disk /"] = {
    disk_partitions = "/"
  }

  /* Define notification mail attributes for notification apply rules in `notifications.conf`. */
  vars.notification["mail"] = {
    /* The UserGroup `icingaadmins` is defined in `users.conf`. */
    groups = [ "icingaadmins" ]
  }
}
```

# Icinga reference documentation
[icinga2 official documentation for the setup](https://icinga.com/docs/icinga2/latest/doc/06-distributed-monitoring/#three-levels-with-master-satellites-and-clients)
![setup](https://drive.google.com/file/d/1j8U_PvDRALjsOVph9acsYL7wES3OzGT2/view?usp=sharing)

