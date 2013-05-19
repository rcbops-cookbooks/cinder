########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages                     # cluster_attribute
default["developer_mode"] = false  # we want secure passwords by default    # cluster_attribute
########################################################################

# lvm/netappiscsi/emc
default["cinder"]["storage"]["provider"] = "lvm"

# netapp settings - set these if you are using netappiscsi/netappnfs
# as the storage provider above
default["cinder"]["storage"]["netapp"]["wsdl_url"] = ""
default["cinder"]["storage"]["netapp"]["login"] = "root"
default["cinder"]["storage"]["netapp"]["password"] = ""
default["cinder"]["storage"]["netapp"]["server_hostname"] = ""
default["cinder"]["storage"]["netapp"]["server_port"] = "8088"
default["cinder"]["storage"]["netapp"]["storage_service"] = ""

default["cinder"]["db"]["name"] = "cinder"                                      # node_attribute
default["cinder"]["db"]["username"] = "cinder"                                  # node_attribute

default["cinder"]["service_tenant_name"] = "service"                          # node_attribute
default["cinder"]["service_user"] = "cinder"                                    # node_attribute
default["cinder"]["service_role"] = "admin"                                   # node_attribute

default["cinder"]["services"]["api"]["scheme"] = "http"                    # node_attribute
default["cinder"]["services"]["api"]["network"] = "public"                 # node_attribute
default["cinder"]["services"]["api"]["port"] = 8776                        # node_attribute
default["cinder"]["services"]["api"]["path"] = "/v1/%(tenant_id)s"         # node_attribute

# solidfire settings - set these if you are using solidfire
# as the storage provider above
default["cinder"]["storage"]["solidfire"]["mvip"] = ""        # Solidfire MVIP address
default["cinder"]["storage"]["solidfire"]["username"] = ""        # Solidfire cluster admin username
default["cinder"]["storage"]["solidfire"]["password"] = ""        # Solidfire cluster admin password

# EMC settings - set these if you are using EMC as the storage provider above.
default["cinder"]["storage"]["emc"]["config"] = "/etc/cinder/cinder_emc_config.xml"
default["cinder"]["storage"]["emc"]["StorageType"] = nil
default["cinder"]["storage"]["emc"]["EcomServerIP"] = nil
default["cinder"]["storage"]["emc"]["EcomServerPort"] = 5988
default["cinder"]["storage"]["emc"]["EcomUserName"] = "admin"
default["cinder"]["storage"]["emc"]["EcomPassword"] = nil
default["cinder"]["storage"]["emc"]["MaskingView"] = nil # VMAX only

# can use a separate 'cinder' network if so desired. Define this network in
# your environment in the same way you define management/nova etc networks
default["cinder"]["services"]["volume"]["network"] = "management"                 # node_attribute

# Logging stuff
default["cinder"]["syslog"]["use"] = true                                    # node_attribute
default["cinder"]["syslog"]["facility"] = "LOG_LOCAL4"                        # node_attribute
default["cinder"]["syslog"]["config_facility"] = "local4"                     # node_attribute

# LOGGING LEVEL
# in order of verbosity (most to least)
# DEBUG, INFO, WARNING, ERROR, CRITICAL
default["cinder"]["config"]["log_verbosity"] = "INFO"                       # node_attributes
default["cinder"]["config"]["storage_availability_zone"] = "nova"                       # node_attributes

case platform_family
when "rhel"
  default["cinder"]["platform"] = {                                                   # node_attribute
    "cinder_api_packages" => ["openstack-cinder"],
    "cinder_api_service" => "openstack-cinder-api",
    "cinder_volume_packages" => ["openstack-cinder"],
    "cinder_volume_service" => "openstack-cinder-volume",
    "cinder_scheduler_packages" => ["openstack-cinder"],
    "cinder_scheduler_service" => "openstack-cinder-scheduler",
    "cinder_iscsitarget_packages" => ["scsi-target-utils"],
    "cinder_iscsitarget_service" => "tgtd",
    "supporting_packages" => ["python-cinderclient", "MySQL-python", "python-keystone"],
    "package_overrides" => ""
  }
  default["cinder"]["storage"]["emc"]["packages"] = ["pywbem"]
when "debian"
  default["cinder"]["platform"] = {                                                   # node_attribute
    "cinder_api_packages" => ["cinder-common", "cinder-api"],
    "cinder_api_service" => "cinder-api",
    "cinder_volume_packages" => ["cinder-volume"],
    "cinder_volume_service" => "cinder-volume",
    "cinder_scheduler_packages" => ["cinder-scheduler"],
    "cinder_scheduler_service" => "cinder-scheduler",
    "cinder_iscsitarget_packages" => ["tgt"],
    "cinder_iscsitarget_service" => "tgt",
    "supporting_packages" => ["python-cinderclient", "python-mysqldb"],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
  default["cinder"]["storage"]["emc"]["packages"] = ["python-pywbem"]
end
