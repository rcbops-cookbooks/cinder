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

ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup", "keystone")
keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

if cinder_info = get_settings_by_role("cinder-setup", "cinder")
  Chef::Log.info("cinder::cinder-api got cinder_info from cinder-setup role holder")
elsif cinder_info = get_settings_by_role("nova-volume", "cinder")
  Chef::Log.info("cinder::cinder-api got cinder_info from nova-volume role holder")
elsif cinder_info = get_settings_by_recipe("cinder::cinder-setup", "cinder")
  Chef::Log.info("cinder::cinder-api got cinder_info from cinder-setup recipe holder")
end

if volume_endpoint = get_access_endpoint("cinder-all", "cinder", "api")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from cinder-all role holder using get_access_endpoint")
elsif volume_endpoint = get_bind_endpoint("cinder", "api")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from cinder-api role holder using get_bind_endpoint")
elsif volume_endpoint = get_access_endpoint("nova-volume", "nova", "volume")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from nova-volume role holder using get_access_endpoint")
end

platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    options platform_options["package_overrides"]
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  end
end

include_recipe "cinder::cinder-common"

# define the cinder-api service so we can call it later
service "cinder-api" do
  service_name platform_options["cinder_api_service"]
  supports :status => true, :restart => true
  unless volume_endpoint["scheme"] == "https"
    action :enable
    subscribes :restart, "cinder_conf[/etc/cinder/cinder.conf]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL
if volume_endpoint["scheme"] == "https"
  include_recipe "cinder::cinder-api-ssl"
else
  if node.recipe?"apache2"
    apache_site "openstack-cinder-api" do
      enable false
      notifies :restart, "service[apache2]", :immediately
    end
  end
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
    "keystone_service_api_ipaddress" => ks_service_endpoint["host"],
    "keystone_admin_api_ipaddress" => ks_admin_endpoint["host"],
    "service_port" => ks_service_endpoint["port"],
    "service_protocol" => ks_service_endpoint["scheme"],
    "admin_port" => ks_admin_endpoint["port"],
    "admin_protocol" => ks_admin_endpoint["scheme"],
    "admin_token" => keystone["admin_token"]
  )
  unless volume_endpoint["scheme"] == "https"
    notifies :restart, "service[cinder-api]", :delayed
  else
    notifies :restart, "service[apache2]", :immediately
  end
end
