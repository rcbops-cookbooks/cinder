maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description      "Installs/Configures cinder"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.5"
recipe        "cinder-api", ""
recipe        "cinder-scheduler", ""
recipe        "cinder-volume", ""

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

%w{ apt database keystone monitoring mysql rabbitmq selinux osops-utils yum }.each do |dep|
  depends dep
end
