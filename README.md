Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[cinder]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Installs the Openstack volume service (codename: cinder) from packages.

http://cinder.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* CentOS >= 6.3
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* database
* mysql
* keystone
* osops-utils
* yum

Recipes
=======

cinder-common
----
- Installs common packages and configs

cinder-api
----
- Installs the cinder-api, sets up the cinder database,
 and cinder service/user/endpoints in keystone

cinder-scheduler
----
- Installs the cinder-scheduler service

cinder-volume
----
- Installs the cinder-volume service and sets up the iscsi helper

Attributes
==========

* `cinder["storage"]["provider"]` - storage provider (lvm/netappiscsi/emc/ebd, defaults to lvm)
* `cinder["storage"]["iscsi"]["ip_address"]` - The ip address of the iscsi provider.  By default, this will be an ip address on the host. 
* `cinder["storage"]["solidfire"]["mvip"]` - Solidfire Storage Service VIP
* `cinder["storage"]["solidfire"]["username"]` - Solidfire Storage Service Admin Username
* `cinder["storage"]["solidfire"]["password"]` - Solidfire Storage Service Admin Password
* `cinder["storage"]["emc"]["config"]` = "/etc/cinder/cinder_emc_config.xml"
* `cinder["storage"]["emc"]["StorageType"]` - EMC Storage Type
* `cinder["storage"]["emc"]["EcomServerIP"]` - IP Address of EMC ECOM
* `cinder["storage"]["emc"]["EcomServerPort"]` - EMC ECOM Port
* `cinder["storage"]["emc"]["EcomUserName"]` - EMC ECOM User
* `cinder["storage"]["emc"]["EcomPassword"]` - EMC ECOM Password
* `cinder["storage"]["netapp"]["iscsi"]["wsdl_url"]` - NetApp device WSDL URL
* `cinder["storage"]["netapp"]["iscsi"]["login"]` - NetApp device login
* `cinder["storage"]["netapp"]["iscsi"]["password"]` - NetApp device password
* `cinder["storage"]["netapp"]["iscsi"]["server_hostname"]` - NetApp device hostname
* `cinder["storage"]["netapp"]["iscsi"]["server_port"]` - NetApp device port
* `cinder["storage"]["netapp"]["iscsi"]["storage_service"]` - NetApp storage service
* `cinder["storage"]["netapp"]["nfsdirect"]["server_hostname"]` - NetApp NFS server hostname
* `cinder["storage"]["netapp"]["nfsdirect"]["port"]` - NetApp NFS port
* `cinder["storage"]["netapp"]["nfsdirect"]["login"]` - NetApp device login
* `cinder["storage"]["netapp"]["nfsdirect"]["password"]` - NetApp device password
* `cinder["storage"]["netapp"]["nfsdirect"]["transport_type"]` - NetApp transport type (http/s)
* `cinder["storage"]["netapp"]["nfsdirect"]["nfs_shares_config"]` - Configuration file location with a list of volumes exported by NetApp
* `cinder["storage"]["netapp"]["nfsdirect"]["export"]` - NetApp exported volume to use
* `cinder["storage"]["rbd"]["rbd_pool"]` - name of the rados pool to use ([volumes])"
* `cinder["storage"]["rbd"]["rbd_user"]` - name of the ceph user ([volumes])
* `cinder["storage"]["rbd"]["rbd_pool_pg_num"]` - number of pg's to create the rbd pool with ([1000])
* `cinder["storage"]["rbd"]["rbd_secret_uuid"]` - an arbitrary uuid to be used with libvirt secret when booting from volumes
* `cinder["db"]["name"]` - name of database to create for cinder
* `cinder["db"]["username"]` - cinder username for database
* `cinder["service_tenant_name"]` - name of tenant to use for the cinder service account in keystone
* `cinder["service_user"]` - cinder service user in keystone
* `cinder["service_role"]` - role for the cinder service user in keystone
* `cinder["services"]["volume"]["scheme"]` - http or https
* `cinder["services"]["volume"]["network"]`  network name to place the service on
* `cinder["services"]["volume"]["port"]` cinder api port
* `cinder["services"]["volume"]["path"]` uri to use when using the cinder api
* `cinder["config"]["log_verbosity"]` - Logging verbosity.  Valid options are DEBUG, INFO, WARNING, ERROR, CRITICAL.  Default is INFO
* `cinder["platform"]` = hash of platform specific package/service names and options

Templates
=====

* `api-paste.ini.erb` - Paste config for cinder API middleware
* `cinder.conf.erb` - Basic cinder.conf file
* `targets.conf.erb` - Config file for tgt (iscsi target software)

Usage
======

Default (LVM)
-------------

By default, the 'lvm' provider is chosen.  No special configuration is
necessary on the chef side, but the cinder volume node must have an
lvm volume group named cinder-volumes. The attributes below can be
adjusted for non-standard LVM configurations:

~~~~~~~~~~~~~
node["cinder"]["storage"]["lvm"]["volume_group"] = "cinder-volumes"
node["cinder"]["storage"]["lvm"]["volume_clear"] = "zero"
node["cinder"]["storage"]["lvm"]["config"] = "/etc/lvm/lvm.conf"
node["cinder"]["storage"]["lvm"]["volume_clear_size"] = 0
node["cinder"]["storage"]["lvm"]["pool_size"] = "None"
node["cinder"]["storage"]["lvm"]["mirrors"] = 0
node["cinder"]["storage"]["lvm"]["volume_driver"] = "cinder.volume.drivers.lvm.LVMISCSIDriver"
~~~~~~~~~~~~~

EMC
---

To use the cinder EMC driver, the following attributes must be set to
appropriate values.  See
https://wiki.openstack.org/wiki/Cinder/EMCVolumeDriver for more
information.

~~~~~~~~~~~~
node["cinder"]["storage"]["iscsi"]["ip_address"] = "IPAddressOfStorageProcessor"
node["cinder"]["storage"]["provider"] = "emc"
node["cinder"]["storage"]["emc"]["config"] = "/etc/cinder/cinder_emc_config.xml"
node["cinder"]["storage"]["emc"]["StorageType"] = "Pool X"
node["cinder"]["storage"]["emc"]["EcomServerIP"] = "IPAddressOfEcomServer"
node["cinder"]["storage"]["emc"]["EcomServerPort"] = 5988
node["cinder"]["storage"]["emc"]["EcomUserName"] = "admin"
node["cinder"]["storage"]["emc"]["EcomPassword"] = "password"
~~~~~~~~~~~~~

SolidFire
---------

To use the solidfire driver, the following attributes must be set to
appropriate values.

~~~~~~~~~~~~~
node["cinder"]["storage"]["provider"] = "solidfire"
node["cinder"]["storage"]["solidfire"]["mvip"] = "Service VIP of SolidFire Device"
node["cinder"]["storage"]["solidfire"]["username"] = "User"
node["cinder"]["storage"]["solidfire"]["password"] = "Password"
~~~~~~~~~~~~~

NetApp - ISCSI
--------------

To use the netapp iscsi driver, the following attributes must be set to 
appropriate values.

~~~~~~~~~~~~~
node["cinder"]["storage"]["provider"] = "netappiscsi"
node["cinder"]["storage"]["netapp"]["iscsi"]["wsdl_url"] = "ISCSI URL from NetApp"
node["cinder"]["storage"]["netapp"]["iscsi"]["login"] = "User"
node["cinder"]["storage"]["netapp"]["iscsi"]["password"] = "Password"
node["cinder"]["storage"]["netapp"]["iscsi"]["server_hostname"] = "NetApp Hostname"
node["cinder"]["storage"]["netapp"]["iscsi"]["server_port"] = "Port to connect ISCSI on NetApp"
node["cinder"]["storage"]["netapp"]["iscsi"]["storage_service"] = ""
~~~~~~~~~~~~~

NetApp - NFS
------------

To use the NetApp nfs driver, the following attributes must be set to
appropriate values.

~~~~~~~~~~~~
node["cinder"]["storage"]["provider"] = "netappnfsdirect"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["server_hostname"] = "NetApp Hostname or IP"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["port"] = "Port to connect to NetApp (80/443)"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["login"] = "User"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["password"] = "Password"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["transport_type"] = "http/https"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["nfs_shares_config"] = "/etc/cinder/shares.txt"
node["cinder"]["storage"]["netapp"]["nfsdirect"]["export"] = "NetApp Exported Volume to use"
~~~~~~~~~~~~

ceph - RBD
----------

To use the ceph RBD driver to create volumes in a ceph cluster, the following
attributes must be set to the appropriate values

~~~~~~~~~~~~
node["cinder"]["storage"]["rbd"]["rbd_pool"] = "name of the rados pool to use ([volumes])"
node["cinder"]["storage"]["rbd"]["rbd_user"] = "name of the ceph user ([volumes])"
node["cinder"]["storage"]["rbd"]["rbd_pool_pg_num"] = "number of pg's to create the rbd pool with ([1000])"
node["cinder"]["storage"]["rbd"]["rbd_secret_uuid"] = "an arbitrary uuid"
~~~~~~~~~~~~

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)

Copyright 2012, Rackspace US, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
