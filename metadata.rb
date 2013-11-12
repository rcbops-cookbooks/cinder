name             "cinder"
maintainer       "Rackspace US, Inc."
license          "Apache 2.0"
description      "Installs/Configures cinder"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION'))
recipe           "cinder-api", ""
recipe           "cinder-scheduler", ""
recipe           "cinder-volume", ""

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ apt database mysql osops-utils yum apache2 ceph }.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.17"
