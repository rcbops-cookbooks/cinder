#
# Cookbook Name:: cinder
# Recipe:: scheduler
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

platform_options = node["cinder"]["platform"]

platform_options["cinder_scheduler_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

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

service "cinder-scheduler" do
  service_name platform_options["cinder_scheduler_service"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
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
  notifies :restart, resources(:service => "cinder-scheduler"), :delayed
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
  notifies :restart, resources(:service => "cinder-scheduler"), :delayed
end

monitoring_procmon "cinder-scheduler" do
  service_name=platform_options["cinder_scheduler_service"]
  process_name "cinder-scheduler"
  script_name service_name
end

monitoring_metric "cinder-scheduler-proc" do
  type "proc"
  proc_name "cinder-scheduler"
  proc_regex platform_options["cinder_scheduler_service"]
  alarms(:failure_min => 2.0)
end
