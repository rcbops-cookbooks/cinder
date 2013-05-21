Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[cinder]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

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

* `cinder["storage"]["provider"]` - storage provider (lvm/netappiscsi,
  defaults to lvm)
* `cinder["storage"]["iscsi"]["ip_address"] - The ip address of the
  iscsi provider.  By default, this will be an ip address on the host. 
* `cinder["storage"]["netapp"]["wsdl_url"]` - NetApp device WSDL URL
* `cinder["storage"]["netapp"]["login"]` - NetApp device login
* `cinder["storage"]["netapp"]["password"]` - NetApp device password
* `cinder["storage"]["netapp"]["server_hostname"]` - NetApp device hostname
* `cinder["storage"]["netapp"]["server_port"]` - NetApp device port
* `cinder["storage"]["netapp"]["storage_service"]` - NetApp storage service
* `cinder["storage"]["solidfire"]["mvip"]` - Solidfire Storage Service VIP
* `cinder["storage"]["solidfire"]["username"]` - Solidfire Storage Service Admin Username
* `cinder["storage"]["solidfire"]["password"]` - Solidfire Storage Service Admin Password
* `cinder["storage"]["emc"]["config"]` = "/etc/cinder/cinder_emc_config.xml"
* `cinder["storage"]["emc"]["StorageType"]` - EMC Storage Type
* `cinder["storage"]["emc"]["EcomServerIP"]` - IP Address of EMC ECOM
* `cinder["storage"]["emc"]["EcomServerPort"]` - EMC ECOM Port
* `cinder["storage"]["emc"]["EcomUserName"]` - EMC ECOM User
* `cinder["storage"]["emc"]["EcomPassword"]` - EMC ECOM Password
* `cinder["db"]["name"]` - name of database to create for cinder
* `cinder["db"]["username"]` - cinder username for database
* `cinder["service_tenant_name"]` - name of tenant to use for the cinder service account in keystone
* `cinder["service_user"]` - cinder service user in keystone
* `cinder["service_role"]` - role for the cinder service user in keystone
* `cinder["services"]["volume"]["scheme"]` - http or https
* `cinder["services"]["volume"]["network"]`  network name to place the service on
* `cinder["services"]["volume"]["port"]` cinder api port
* `cinder["services"]["volume"]["path"]` uri to use when using the cinder api
* `cinder["syslog"]["use"]`
* `cinder["syslog"]["facility"]`
* `cinder["syslog"]["config_facility"]`
* `cinder["config"]["log_verbosity"]` - Logging verbosity.  Valid options are DEBUG, INFO, WARNING, ERROR, CRITICAL.  Default is INFO
* `cinder["platform"]` = hash of platform specific package/service names and options

Templates
=====

* `24-cinder.conf.erb` - rsyslog config file for cinder
* `api-paste.ini.erb` - Paste config for cinder API middleware
* `cinder.conf.erb` - Basic cinder.conf file
* `cinder-logging.conf.erb` - Logging config for cinder services
* `targets.conf.erb` - Config file for tgt (iscsi target software)

Usage
======

Default (LVM)
-------------

By default, the 'lvm' provider is chosen.  No special configuration is
necessary on the chef side, but the cinder volume node must have an
lvm volume group named cinder volumes.

EMC
---

To use the cinder EMC driver, the following attributes must be set to
appropriate values.  See
https://wiki.openstack.org/wiki/Cinder/EMCVolumeDriver for more
information.

node["cinder"]["storage"]["iscsi"]["ip_address"] = "IPAddressOfStorageProcessor"
node["cinder"]["storage"]["provider"] = "emc"
node["cinder"]["storage"]["emc"]["config"] = "/etc/cinder/cinder_emc_config.xml"
node["cinder"]["storage"]["emc"]["StorageType"] = "Pool X"
node["cinder"]["storage"]["emc"]["EcomServerIP"] = "IPAddressOfEcomServer"
node["cinder"]["storage"]["emc"]["EcomServerPort"] = 5988
node["cinder"]["storage"]["emc"]["EcomUserName"] = "admin"
node["cinder"]["storage"]["emc"]["EcomPassword"] = "password"


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
