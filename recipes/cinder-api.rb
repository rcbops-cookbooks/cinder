#
# Cookbook Name:: cinder
# Recipe:: cinder-api
#
# Copyright 2012, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


include_recipe "cinder::cinder-rsyslog"
include_recipe "mysql::client"
include_recipe "mysql::ruby"

platform_options = node["cinder"]["platform"]

ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

if cinder_info = get_settings_by_role("cinder-setup", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from cinder-setup role holder")
elsif cinder_info = get_settings_by_role("nova-volume", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from nova-volume role holder")
elsif cinder_info = get_settings_by_recipe("cinder::cinder-setup", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from cinder-setup recipe holder")
end

rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
cinder_api = get_bind_endpoint("cinder", "api")

cinder_volume_network = node["cinder"]["services"]["volume"]["network"]
iscsi_ip_address = get_ip_for_net(cinder_volume_network)

# install packages for cinder-api
platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

# define the cinder-api service so we can call it later
service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  action :enable
end

template "/etc/cinder/logging.conf" do
  source "cinder-logging.conf.erb"
  owner "cinder"
  group "cinder"
  mode "0600"
  variables("use_syslog" => node["cinder"]["syslog"]["use"],
            "log_facility" => node["cinder"]["syslog"]["facility"],
            "log_verbosity" => node["cinder"]["config"]["log_verbosity"]
           )
  notifies :restart, resources(:service => "cinder-api"), :delayed
end

template "/etc/cinder/cinder.conf" do
  source "cinder.conf.erb"
  owner "cinder"
  group "cinder"
  mode "0600"
  variables(
    "netapp_wsdl_url" => node["cinder"]["storage"]["netapp"]["wsdl_url"],
    "netapp_login" => node["cinder"]["storage"]["netapp"]["login"],
    "netapp_password" => node["cinder"]["storage"]["netapp"]["password"],
    "netapp_server_hostname" => node["cinder"]["storage"]["netapp"]["server_hostname"],
    "netapp_server_port" => node["cinder"]["storage"]["netapp"]["server_port"],
    "netapp_storage_service" => node["cinder"]["storage"]["netapp"]["storage_service"],
    "db_ip_address" => mysql_info["host"],
    "db_user" => node["cinder"]["db"]["username"],
    "db_password" => cinder_info["db"]["password"],
    "db_name" => node["cinder"]["db"]["name"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
    "cinder_api_listen_ip" => cinder_api["host"],
    "cinder_api_listen_port" => cinder_api["port"],
    "iscsi_ip_address" => iscsi_ip_address
  )
  notifies :restart, resources(:service => "cinder-api"), :delayed
end

template "/etc/cinder/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "cinder"
  group "cinder"
  mode "0600"
  variables(
    "service_tenant_name" => node["cinder"]["service_tenant_name"],
    "service_user" => node["cinder"]["service_user"],
    "service_pass" => cinder_info["service_pass"],
    "keystone_api_ipaddress" => ks_service_endpoint["host"],
    "service_port" => ks_service_endpoint["port"],
    "admin_port" => ks_admin_endpoint["port"],
    "admin_token" => keystone["admin_token"]
  )
  notifies :restart, resources(:service => "cinder-api"), :delayed
end

# now we are using mysql, ditch the original sqlite file
file "/var/lib/cinder/cinder.sqlite" do
      action :delete
end

monitoring_procmon "cinder-api" do
  service_name=platform_options["cinder_api_service"]
  process_name "cinder-api"
  script_name service_name
end

monitoring_metric "cinder-api-proc" do
  type "proc"
  proc_name "cinder-api"
  proc_regex platform_options["cinder_api_service"]
  alarms(:failure_min => 2.0)
end
