########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages                     # cluster_attribute
########################################################################

# Define the ha policy for queues.  If you change this to true
# after you have already deployed you will need to wipe the RabbitMQ
# database by stopping rabbitmq, removing /var/lib/rabbitmq/mnesia
# and starting rabbitmq back up.  Failure to do so will cause the
# OpenStack services to fail to connect to RabbitMQ.
default["cinder"]["rabbitmq"]["use_ha_queues"] = false

# lvm/netappiscsi/emc/solidfire/netappnfsdirect
default["cinder"]["storage"]["provider"] = "lvm"
default["cinder"]["storage"]["iscsi"]["ip_address"] = nil
default["cinder"]["storage"]["enable_multipath"] = false                    # if using emc set to true to enable multi-path

default["cinder"]["db"]["name"] = "cinder"
default["cinder"]["db"]["username"] = "cinder"

default["cinder"]["service_tenant_name"] = "service"
default["cinder"]["service_user"] = "cinder"
default["cinder"]["service_role"] = "admin"

default["cinder"]["services"]["api"]["scheme"] = "http"
default["cinder"]["services"]["api"]["network"] = "public"
default["cinder"]["services"]["api"]["port"] = 8776
default["cinder"]["services"]["api"]["path"] = "/v1/%(tenant_id)s"

default["cinder"]["services"]["api"]["cert_file"] = "cinder.pem"
default["cinder"]["services"]["api"]["key_file"] = "cinder.key"
default["cinder"]["services"]["api"]["wsgi_file"] = "cinder-api"

default["cinder"]["services"]["internal-api"]["scheme"] = "http"
default["cinder"]["services"]["internal-api"]["network"] = "management"
default["cinder"]["services"]["internal-api"]["port"] = 8776
default["cinder"]["services"]["internal-api"]["path"] = "/v1/%(tenant_id)s"

default["cinder"]["services"]["admin-api"]["scheme"] = "http"
default["cinder"]["services"]["admin-api"]["network"] = "management"
default["cinder"]["services"]["admin-api"]["port"] = 8776
default["cinder"]["services"]["admin-api"]["path"] = "/v1/%(tenant_id)s"

# LVM Settings
default["cinder"]["storage"]["lvm"]["volume_group"] = "cinder-volumes"     # name from volume group
default["cinder"]["storage"]["lvm"]["volume_clear"] = "zero"               # none, zero, shred
default["cinder"]["storage"]["lvm"]["config"] = "/etc/lvm/lvm.conf"        # Path of LVM config file

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

# netapp settings - set these if you are using netappiscsi/netappnfs
# as the storage provider above
default["cinder"]["storage"]["netapp"]["iscsi"]["wsdl_url"] = ""
default["cinder"]["storage"]["netapp"]["iscsi"]["login"] = "root"
default["cinder"]["storage"]["netapp"]["iscsi"]["password"] = ""
default["cinder"]["storage"]["netapp"]["iscsi"]["server_hostname"] = ""
default["cinder"]["storage"]["netapp"]["iscsi"]["server_port"] = "8088"
default["cinder"]["storage"]["netapp"]["iscsi"]["storage_service"] = ""

# NetApp NFS Direct Settings - set these if you are using the Netapp NFS direct driver:
# http://docs.openstack.org/grizzly/openstack-block-storage/admin/content/netapp-nfs-driver-direct-7mode.html
default["cinder"]["storage"]["netapp"]["nfsdirect"]["server_hostname"] = ""
default["cinder"]["storage"]["netapp"]["nfsdirect"]["port"] = "443"
default["cinder"]["storage"]["netapp"]["nfsdirect"]["login"] = ""
default["cinder"]["storage"]["netapp"]["nfsdirect"]["password"] = ""
default["cinder"]["storage"]["netapp"]["nfsdirect"]["transport_type"] = "https"
default["cinder"]["storage"]["netapp"]["nfsdirect"]["nfs_shares_config"] = "/etc/cinder/shares.txt"
default["cinder"]["storage"]["netapp"]["nfsdirect"]["export"] = ""

# Ceph RBD settings - set these if you're using Ceph RBD Volumes
# http://docs.openstack.org/grizzly/openstack-block-storage/admin/content/ceph-rados.html
# http://ceph.com/docs/next/rbd/rbd-openstack/
default["cinder"]["storage"]["rbd"]["rbd_pool"] = "volumes"
default["cinder"]["storage"]["rbd"]["rbd_user"] = "volumes"
default["cinder"]["storage"]["rbd"]["rbd_secret_uuid"] = ""

# can use a separate 'cinder' network if so desired. Define this network in
# your environment in the same way you define management/nova etc networks
default["cinder"]["services"]["volume"]["network"] = "management"

# LOGGING LEVEL
# in order of verbosity (most to least)
# DEBUG, INFO, WARNING, ERROR, CRITICAL
default["cinder"]["config"]["log_verbosity"] = "INFO"
default["cinder"]["config"]["storage_availability_zone"] = "nova"
default["cinder"]["config"]["max_gigabytes"] = "10000"

case platform_family
when "rhel"
  default["cinder"]["platform"] = {
    "cinder_common_packages" => ["openstack-cinder"],
    "cinder_api_packages" => ["openstack-cinder"],
    "cinder_api_service" => "openstack-cinder-api",
    "cinder_volume_packages" => ["openstack-cinder", "iscsi-initiator-utils", "qemu-img"],
    "cinder_volume_service" => "openstack-cinder-volume",
    "cinder_scheduler_packages" => ["openstack-cinder"],
    "cinder_scheduler_service" => "openstack-cinder-scheduler",
    "cinder_iscsitarget_packages" => ["scsi-target-utils"],
    "cinder_iscsitarget_service" => "tgtd",
    "supporting_packages" => ["python-cinderclient", "MySQL-python", "python-keystone"],
    "package_overrides" => ""
  }
  default["cinder"]["storage"]["emc"]["packages"] = ["pywbem"]
  default["cinder"]["storage"]["netapp"]["nfsdirect"]["packages"] = ["nfs-utils", "sysfsutils"]
  default["cinder"]["ssl"]["dir"] = "/etc/pki/tls"
when "debian"
  default["cinder"]["platform"] = {
    "cinder_common_packages" => ["cinder-common"],
    "cinder_api_packages" => ["cinder-api"],
    "cinder_api_service" => "cinder-api",
    "cinder_volume_packages" => ["cinder-volume", "open-iscsi", "qemu-utils"],
    "cinder_volume_service" => "cinder-volume",
    "cinder_scheduler_packages" => ["cinder-scheduler"],
    "cinder_scheduler_service" => "cinder-scheduler",
    "cinder_iscsitarget_packages" => ["tgt"],
    "cinder_iscsitarget_service" => "tgt",
    "supporting_packages" => ["python-cinderclient", "python-mysqldb"],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
  default["cinder"]["storage"]["emc"]["packages"] = ["python-pywbem"]
  default["cinder"]["storage"]["netapp"]["nfsdirect"]["packages"] = ["nfs-common", "sysfsutils"]
  default["cinder"]["ssl"]["dir"] = "/etc/ssl"
end
