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

platform_options["cinder_api_packages"].each do |pkg|
  package pkg do
    options platform_options["package_options"]
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  end
end

include_recipe "cinder::cinder-common"

if volume_endpoint = get_access_endpoint("cinder-all", "cinder", "api")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from cinder-all role holder using get_access_endpoint")
elsif volume_endpoint = get_bind_endpoint("cinder", "api")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from cinder-api role holder using get_bind_endpoint")
elsif volume_endpoint = get_access_endpoint("nova-volume", "nova", "volume")
  Chef::Log.debug("cinder::cinder-api got cinder endpoint info from nova-volume role holder using get_access_endpoint")
end

# define the cinder-api service
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
