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

include_recipe "mysql::client"
include_recipe "mysql::ruby"

platform_options = node["cinder"]["platform"]

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")
# Get keystone settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

# Get cinder settings from role[cinder-setup]
cinder_info = get_settings_by_role("cinder-setup", "cinder")

# install packages for cinder-api
platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_overrides"]
  end
end

include_recipe "cinder::cinder-common"

# define the cinder-api service so we can call it later
service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "template[/etc/cinder/cinder.conf]", :delayed
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
  notifies :restart, "service[cinder-api]", :delayed
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
