#
# Cookbook Name:: cinder
# Recipe:: cinder-common
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

# Create Cinder User
user "cinder" do
  comment "openstack cinder user"
  system true
  home "/var/lib/cinder"
  shell "/bin/false"
  not_if "id cinder"
end

# Create Cinder Config Directory
directory "/etc/cinder" do
  owner "cinder"
  group "cinder"
  mode "755"
  recursive true
end

# Set the policy json
cookbook_file "/etc/cinder/#{node["cinder"]["policy"]}" do
  source "openstack_defaults/policy.json"
  mode 0644
  owner "cinder"
  group "cinder"
end

# Set the policy json
cookbook_file "/etc/cinder/api-paste.ini" do
  source "openstack_defaults/api-paste.ini"
  mode 0644
  owner "cinder"
  group "cinder"
end

# Setup Conf File
cinder_conf "/etc/cinder/cinder.conf" do
  action :create
end

platform_options = node["cinder"]["platform"]

pkgs = platform_options["cinder_common_packages"] +
  platform_options["supporting_packages"]

pkgs.each do |pkg|
  include_recipe "osops-utils::#{pkg}"
end

execute "cinder-manage db sync" do
  user "cinder"
  group "cinder"
  command "cinder-manage db sync"
  action :run
end

# now we are using mysql in the config file, ditch the original sqlite file
file "/var/lib/cinder/cinder.sqlite" do
  action :delete
end
