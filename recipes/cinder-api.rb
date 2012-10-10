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
#include_recipe "monitoring"

platform_options = node["cinder"]["platform"]

ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
keystone = get_settings_by_role("keystone", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

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
#  not_if "nova-manage db version && test $(nova-manage db version) -gt 0"
end

# define the cinder-api service so we can call it later
service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  action :enable
#  subscribes :restart, resources(:template => "/etc/cinder/cinder.conf"), :delayed
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
  notifies :run, resources(:execute => "cinder-manage db sync"), :immediately
  notifies :restart, resources(:service => "cinder-api"), :immediately
end

# now we are using mysql, ditch the original sqlite file
file "/var/lib/cinder/cinder.sqlite" do
      action :delete
end

#monitoring_metric "nova-plugin" do
#  type "pyscript"
#  script "nova_plugin.py"
#  options("Username" => keystone_admin_user,
#          "Password" => keystone_admin_password,
#          "TenantName" => keystone_admin_tenant,
#          "AuthURL" => ks_service_endpoint["uri"])
#end



#monitoring_procmon "nova-api-os-volume" do
#  service_name=platform_options["api_os_volume_service"]
#  process_name "nova-api-os-volume"
#  script_name service_name
#end

#monitoring_metric "nova-api-os-volume-proc" do
#  type "proc"
#  proc_name "nova-api-os-volume"
#  proc_regex platform_options["api_os_volume_service"]
#
#  alarms(:failure_min => 2.0)
#end


