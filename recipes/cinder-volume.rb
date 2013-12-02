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

# Create Cinder lock dir
directory "/var/lock/cinder/" do
  mode "755"
  owner "cinder"
  group "root"
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

  when "rbd"

    if rcb_safe_deref(node, "ceph.config.fsid")

      include_recipe "ceph::repo"
      include_recipe "ceph"
      include_recipe "ceph::conf"

      rbd_user = node['cinder']['storage']['rbd']['rbd_user']
      rbd_pool = node['cinder']['storage']['rbd']['rbd_pool']
      rbd_pool_pg_num = node['cinder']['storage']['rbd']['rbd_pool_pg_num']
      rbd_secret_uuid = node['cinder']['storage']['rbd']['rbd_secret_uuid']

      # do all this in a ruby_block so it doesn't get executed at compile time
      ruby_block "create cinder cephx client" do
        block do

          rbd_user_keyring_file="/etc/ceph/ceph.client.#{rbd_user}.keyring" 
          mon_keyring_file = "#{Chef::Config[:file_cache_path]}/#{node['hostname']}.mon.keyring"

          unless File.exist?(rbd_user_keyring_file)

            monitor_secret = if node['ceph']['encrypted_data_bags']
                               secret = Chef::EncryptedDataBagItem.load_secret(node["ceph"]["mon"]["secret_file"])
                               Chef::EncryptedDataBagItem.load("ceph", "mon", secret)["secret"]
                             else
                               node["ceph"]["monitor-secret"]
                             end

            # create the mon keyring temporarily
            Mixlib::ShellOut.new("ceph-authtool '#{mon_keyring_file}' --create-keyring --name='mon.' --add-key='#{monitor_secret}' --cap mon 'allow *'").run_command

            # Ensure the rbd user exists and has appropriate pool permissions).
            # TODO(mancdaz): get glance pool name by search, and only grant access if glance is using rbd
            Mixlib::ShellOut.new("ceph auth get-or-create client.#{rbd_user} --name='mon.' --keyring='#{mon_keyring_file}' ").run_command
            Mixlib::ShellOut.new("ceph auth caps client.#{rbd_user} --name='mon.' --keyring='#{mon_keyring_file}' mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=#{rbd_pool}, allow rx pool=images'").run_command

            # get the key for this user and set it to the node hash so it's
            # searchable as nova::libvirt needs it
            rbd_user_key = Mixlib::ShellOut.new("ceph auth get-key client.#{rbd_user} --name='mon.' --keyring='#{mon_keyring_file}'").run_command.stdout
            node.set['cinder']['storage']['rbd']['rbd_user_key'] = rbd_user_key

            # get the full client, with caps, and write it out to file
            # TODO(mancdaz): discover ceph config dir rather than hardcode
            rbd_user_keyring = Mixlib::ShellOut.new("ceph auth get client.#{rbd_user} --name='mon.' --keyring='#{mon_keyring_file}'").run_command.stdout
            f = File.open("/etc/ceph/ceph.client.#{rbd_user}.keyring", 'w')
            f.write(rbd_user_keyring)
            f.close

            # create the pool with provided pg_num
            Mixlib::ShellOut.new("ceph osd pool create #{rbd_pool} #{rbd_pool_pg_num} #{rbd_pool_pg_num} --name='mon.' --keyring='#{mon_keyring_file}'").run_command

            # remove the temporary mon keyring
            File.delete(mon_keyring_file)
          end
        end
      end
    end
end
