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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

# Allow for using a well known db password
if node["developer_mode"]
  node.set_unless["cinder"]["db"]["password"] = "cinder"
else
  node.set_unless["cinder"]["db"]["password"] = secure_password
end

# Set a secure keystone service password
node.set_unless['cinder']['service_pass'] = secure_password

include_recipe "mysql::client"
include_recipe "mysql::ruby"

platform_options = node["cinder"]["platform"]

ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
keystone = get_settings_by_role("keystone", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

volume_endpoint = get_access_endpoint("cinder-volume", "cinder", "volume")
if volume_endpoint.nil?
    volume_endpoint = get_access_endpoint("nova-volume", "nova", "volume")
end

#creates cinder db and user
#function defined in osops-utils/libraries
mysql_info = create_db_and_user("mysql",
                   node["cinder"]["db"]["name"],
                   node["cinder"]["db"]["username"],
                   node["cinder"]["db"]["password"])

rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

# install packages for cinder-api
platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

# define the command but call it after we drop in our config files
execute "cinder-manage db sync" do
  command "cinder-manage db sync"
  action :nothing
end

# define the cinder-api service so we can call it later
service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  action :enable
end

template "/etc/cinder/cinder.conf" do
  source "cinder.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "db_ip_address" => mysql_info["bind_address"],
    "db_user" => node["cinder"]["db"]["username"],
    "db_password" => node["cinder"]["db"]["password"],
    "db_name" => node["cinder"]["db"]["name"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"]
  )
  notifies :run, resources(:execute => "cinder-manage db sync"), :immediately
  notifies :restart, resources(:service => "cinder-api"), :delayed
end

template "/etc/cinder/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "service_tenant_name" => node["cinder"]["service_tenant_name"],
    "service_user" => node["cinder"]["service_user"],
    "service_pass" => node["cinder"]["service_pass"],
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

# Register Cinder Volume Service
keystone_register "Register Cinder Volume Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  action :create_service
end

# Register Cinder Endpoint
keystone_register "Register Volume Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "volume"
  endpoint_region "RegionOne"
  endpoint_adminurl volume_endpoint["uri"]
  endpoint_internalurl volume_endpoint["uri"]
  endpoint_publicurl volume_endpoint["uri"]
  action :create_endpoint
end

# Register Service User
keystone_register "Register Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  user_pass node["cinder"]["service_pass"]
  user_enabled "true" # Not required as this is the default
  action :create_user
end

## Grant Admin role to Service User for Service Tenant ##
keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  role_name node["cinder"]["service_role"]
  action :grant_role
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
