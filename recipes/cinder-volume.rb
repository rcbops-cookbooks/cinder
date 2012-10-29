#
# Cookbook Name:: cinder
# Recipe:: cinder-volume
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

platform_options = node["cinder"]["platform"]

platform_options["cinder_volume_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

platform_options["cinder_iscsitarget_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
cinder_info = get_settings_by_role("cinder-api", "cinder")

# set to enabled right now but can be toggled
service "cinder-volume" do
  service_name platform_options["cinder_volume_service"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

template "/etc/cinder/cinder.conf" do
  source "cinder.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    "db_ip_address" => mysql_info["host"],
    "db_user" => node["cinder"]["db"]["username"],
    "db_password" => cinder_info["db"]["password"],
    "db_name" => node["cinder"]["db"]["name"],
    "rabbit_ipaddress" => rabbit_info["host"],
    "rabbit_port" => rabbit_info["port"],
  )
  notifies :restart, resources(:service => "cinder-volume"), :delayed
end

service "iscsitarget" do
  service_name platform_options["cinder_iscsitarget_service"]
  supports :status => true, :restart => true
  action :enable
end

template "/etc/tgt/targets.conf" do
  source "targets.conf.erb"
  mode "600"
  notifies :restart, resources(:service => "iscsitarget"), :immediately
end

monitoring_procmon "cinder-volume" do
  service_name=platform_options["cinder_volume_service"]
  process_name "cinder-volume"
  script_name service_name
end

monitoring_metric "cinder-volume-proc" do
  type "proc"
  proc_name "cinder-volume"
  proc_regex platform_options["cinder_volume_service"]
  alarms(:failure_min => 2.0)
end
