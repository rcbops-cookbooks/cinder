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

pkgs = platform_options["cinder_volume_packages"] + platform_options["cinder_iscsitarget_packages"]

pkgs.each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

include_recipe "cinder::cinder-common"

# set to enabled right now but can be toggled
service "cinder-volume" do
  service_name platform_options["cinder_volume_service"]
  supports :status => true, :restart => true
  action [ :enable ]
  subscribes :restart, "cinder_conf[/etc/cinder/cinder.conf]", :delayed
end

service "iscsitarget" do
  service_name platform_options["cinder_iscsitarget_service"]
  supports :status => true, :restart => true
  action :enable
end

# Create Cinder Config Directory
directory "/etc/tgt/conf.d/" do
  mode "755"
  recursive true
end

# Drop targets conf
cookbook_file "/etc/tgt/targets.conf" do
  source "openstack_defaults/targets.conf"
  mode "644"
  notifies :restart, "service[iscsitarget]", :immediately
end

# Drop cinder conf
cookbook_file "/etc/tgt/conf.d/cinder_tgt.conf" do
  source "openstack_defaults/cinder_tgt.conf"
  mode "644"
  notifies :restart, "service[iscsitarget]", :immediately
end

case node["cinder"]["storage"]["provider"]
  when "emc"
    d = node["cinder"]["storage"]["emc"]
    keys = %w[StorageType EcomServerIP EcomServerPort EcomUserName EcomPassword]
    for word in keys
      if not d.key? word
        msg = "Cinder's emc volume provider was selected, but #{word} was not set.'"
        Chef::Application.fatal! msg
      end
    end
    node["cinder"]["storage"]["emc"]["packages"].each do |pkg|
      package pkg do
        action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
        options platform_options["package_options"]
      end
    end

    template node["cinder"]["storage"]["emc"]["config"] do
      source "cinder_emc_config.xml.erb"
      variables d
      mode "644"
      notifies :restart, "service[iscsitarget]", :immediately
    end
  when "netappnfsdirect"
    node["cinder"]["storage"]["netapp"]["nfsdirect"]["packages"].each do |pkg|
      package pkg do
        action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
        options platform_options["package_options"]
      end
    end

    template node["cinder"]["storage"]["netapp"]["nfsdirect"]["nfs_shares_config"] do
      source "cinder_netapp_nfs_shares.txt.erb"
      mode "0600"
      owner "cinder"
      group "cinder"
      variables(
       "host" => node["cinder"]["storage"]["netapp"]["nfsdirect"]["server_hostname"],
       "nfs_export" => node["cinder"]["storage"]["netapp"]["nfsdirect"]["export"]
      )
      notifies :restart, "service[cinder-volume]", :delayed
    end
  when "lvm"
    template node["cinder"]["storage"]["lvm"]["config"] do
      source "lvm.conf.erb"
      mode 0644
      variables(
        "volume_group" => node["cinder"]["storage"]["lvm"]["volume_group"]
      )
    end
end
