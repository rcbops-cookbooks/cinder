########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages                     # cluster_attribute
default["developer_mode"] = false  # we want secure passwords by default    # cluster_attribute
########################################################################

default["cinder"]["db"]["name"] = "cinder"                                      # node_attribute
default["cinder"]["db"]["username"] = "cinder"                                  # node_attribute

default["cinder"]["service_tenant_name"] = "service"                          # node_attribute
default["cinder"]["service_user"] = "cinder"                                    # node_attribute
default["cinder"]["service_role"] = "admin"                                   # node_attribute

default["cinder"]["services"]["volume"]["scheme"] = "http"                    # node_attribute
default["cinder"]["services"]["volume"]["network"] = "public"                 # node_attribute
default["cinder"]["services"]["volume"]["port"] = 8776                        # node_attribute
default["cinder"]["services"]["volume"]["path"] = "/v1/%(tenant_id)s"         # node_attribute

# Logging stuff
default["cinder"]["syslog"]["use"] = true                                     # node_attribute
default["cinder"]["syslog"]["facility"] = "LOG_LOCAL1"                        # node_attribute
default["cinder"]["syslog"]["config_facility"] = "local1"                     # node_attribute

# can this be wedged into the "api" endpoint?                               # node_attribute
default["cinder"]["compute"]["region"] = "RegionOne"                          # node_attribute

default["cinder"]["config"]["availability_zone"] = "cinder"                             # node_attribute
default["cinder"]["config"]["default_schedule_zone"] = "cinder"                         # cluster_attribute

case platform
when "fedora", "redhat", "centos"
  default["cinder"]["platform"] = {                                                   # node_attribute
    "api_os_volume_packages" => ["openstack-cinder-api"],
    "api_os_volume_service" => "openstack-cinder-api",
    "cinder_volume_packages" => ["openstack-cinder-volume"],
    "cinder_volume_service" => "openstack-cinder-volume",
    "package_overrides" => ""
  }
when "ubuntu"
  default["cinder"]["platform"] = {                                                   # node_attribute
    "cinder_api_packages" => ["cinder-common", "cinder-api", "python-cinderclient"],
    "cinder_api_service" => "cinder-api",
    "cinder_volume_packages" => ["cinder-volume"],
    "cinder_volume_service" => "cinder-volume",
    "cinder_scheduler_packages" => ["cinder-scheduler"],
    "cinder_scheduler_service" => "cinder-scheduler",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
