Description
===========

Installs the Openstack volume service (codename: cinder) from packages.

http://cinder.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* Ubuntu-12.04
* Fedora-17

Cookbooks
---------

The following cookbooks are dependencies:

* apt
* database
* glance
* keystone
* mysql
* openssh
* rabbitmq
* selinux (Fedora)
* osops-utils

Recipes
=======

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
* `cinder["platform"]` = hash of platform specific package/service names and options
* `cinder["config"]["log_verbosity"]` - Logging verbosity.  Valid options are DEBUG, INFO, WARNING, ERROR, CRITICAL.  Default is INFO

Templates
=====
* `api-paste.ini.erb` - Paste config for cinder API middleware
* `cinder.conf.erb` - Basic cinder.conf file
* `targets.conf.erb` - config file for tgt (iscsi target software)

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  

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
