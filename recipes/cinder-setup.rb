#
# Cookbook Name:: cinder
# Recipe:: cinder-setup
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
if node["developer_mode"] == true
  node.set_unless["cinder"]["db"]["password"] = "cinder"
else
  node.set_unless["cinder"]["db"]["password"] = secure_password
end

# Set a secure keystone service password
node.set_unless['cinder']['service_pass'] = secure_password

include_recipe "mysql::client"
include_recipe "mysql::ruby"

platform_options = node["cinder"]["platform"]

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
keystone = get_settings_by_role("keystone-setup", "keystone")

if volume_endpoint = get_bind_endpoint("cinder", "api")
  admin_volume_endpoint = get_bind_endpoint("cinder", "admin-api")
  internal_volume_endpoint = get_bind_endpoint("cinder", "internal-api")
  Chef::Log.debug("cinder::cinder-setup got cinder endpoint info from cinder-all role holder using get_access_endpoint")
elsif volume_endpoint = get_bind_endpoint("nova", "volume")
  admin_volume_endpoint = volume_endpoint
  internal_volume_endpoint = volume_endpoint
  Chef::Log.debug("cinder::cinder-setup got cinder endpoint info from nova-volume role holder using get_access_endpoint")
end

Chef::Log.debug("volume_endpoint contains: #{volume_endpoint}")

#creates cinder db and user
#function defined in osops-utils/libraries
create_db_and_user(
    "mysql",
    node["cinder"]["db"]["name"],
    node["cinder"]["db"]["username"],
    node["cinder"]["db"]["password"]
)

include_recipe "cinder::cinder-common"

# Register Cinder Volume Service
keystone_service "Register Cinder Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "cinder"
  service_type "volume"
  service_description "Cinder Volume Service"
  action :create
end

# Register Cinder Endpoint
keystone_endpoint "Register Cinder Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "volume"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl admin_volume_endpoint["uri"]
  endpoint_internalurl internal_volume_endpoint["uri"]
  endpoint_publicurl volume_endpoint["uri"]
  action :recreate
end

# Register Service User
keystone_user "Register Cinder Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  user_pass node["cinder"]["service_pass"]
  user_enabled true # Not required as this is the default
  action :create
end

## Grant Admin role to Service User for Service Tenant ##
keystone_role "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["cinder"]["service_tenant_name"]
  user_name node["cinder"]["service_user"]
  role_name node["cinder"]["service_role"]
  action :grant
end
