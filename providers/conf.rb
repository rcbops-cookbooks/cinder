use_inline_resources if Gem::Version.new(Chef::VERSION) >= Gem::Version.new('11')

action :create do
  # Don't log during converge in LWP, it unconditionally marks the LWR
  # as updated; log during compile phase only.
  Chef::Log.info("Creating #{new_resource.name}")

  # Search for required endpoints
  rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
  rabbit_settings = get_settings_by_role("rabbitmq-server", "rabbitmq")
  mysql_info = get_mysql_endpoint
  glance_api = get_access_endpoint("glance-api", "glance", "api")
  cinder_api = get_bind_endpoint("cinder", "api")

  cinder_volume_network = node["cinder"]["services"]["volume"]["network"]

  # Set iscsi address
  iscsi_ip_address = node["cinder"]["storage"]["iscsi"]["ip_address"]
  iscsi_ip_address ||= get_ip_for_net(cinder_volume_network)

  # Check for which type of setup we are using here.
  if cinder_info = get_settings_by_role("cinder-setup", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from cinder-setup role holder")
  elsif cinder_info = get_settings_by_role("nova-volume", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from nova-volume role holder")
  elsif cinder_info = get_settings_by_recipe("cinder::cinder-setup", "cinder")
    Chef::Log.info("cinder::cinder-volume got cinder_info from cinder-setup recipe holder")
  end

  # Currently we support SolidFire, EMC VMAX/VNX, NetApp ISCSI (onCommand),
  # NetApp NFSDirect and ceph RBD
  storage_provider = node["cinder"]["storage"]["provider"]
  storage_options = {}
  case storage_provider
  when "solidfire"
    storage_options["volume_driver"] = "cinder.volume.drivers.solidfire.SolidFire"
    storage_options["san_ip"] = node["cinder"]["storage"][storage_provider]["mvip"]
    storage_options["san_login"] = node["cinder"]["storage"][storage_provider]["username"]
    storage_options["san_password"] = node["cinder"]["storage"][storage_provider]["password"]
  when "netappiscsi"
    storage_options["volume_driver"] = "cinder.volume.drivers.netapp.NetAppISCSIDriver"
    storage_options["netapp_wsdl_url"] = node["cinder"]["storage"]["netapp"]["iscsi"]["wsdl_url"]
    storage_options["netapp_login"] = node["cinder"]["storage"]["netapp"]["iscsi"]["login"]
    storage_options["netapp_password"] = node["cinder"]["storage"]["netapp"]["iscsi"]["password"]
    storage_options["netapp_server_hostname"] = node["cinder"]["storage"]["netapp"]["iscsi"]["server_hostname"]
    storage_options["netapp_server_port"] = node["cinder"]["storage"]["netapp"]["iscsi"]["server_port"]
    storage_options["netapp_storage_service"] = node["cinder"]["storage"]["netapp"]["iscsi"]["storage_service"]
  when "netappnfsdirect"
    storage_options["volume_driver"] = "cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver"
    storage_options["netapp_server_hostname"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["server_hostname"]
    storage_options["netapp_server_port"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["port"]
    storage_options["netapp_login"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["login"]
    storage_options["netapp_password"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["password"]
    storage_options["netapp_transport_type"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["transport_type"]
    storage_options["nfs_shares_config"] = node["cinder"]["storage"]["netapp"]["nfsdirect"]["nfs_shares_config"]
  when "emc"
    storage_options["iscsi_target_prefix"] = "iqn.1992-04.com.emc"
    storage_options["volume_driver"] = "cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver"
    storage_options["cinder_emc_config_file"] = "/etc/cinder/cinder_emc_config.xml"
  when "lvm"
    storage_options["volume_driver"] = node["cinder"]["storage"]["lvm"]["volume_driver"]
    storage_options["volume_group"] = node["cinder"]["storage"]["lvm"]["volume_group"]
    storage_options["volume_clear"] = node["cinder"]["storage"]["lvm"]["volume_clear"]
    storage_options["volume_clear_size"] = node["cinder"]["storage"]["lvm"]["volume_clear_size"]
    storage_options["volume_pool_size"] = node["cinder"]["storage"]["lvm"]["pool_size"]
  when "rbd"
    storage_options["volume_driver"] = "cinder.volume.drivers.rbd.RBDDriver"
    storage_options["rbd_pool"] = node["cinder"]["storage"]["rbd"]["rbd_pool"]
    storage_options["rbd_user"] = node["cinder"]["storage"]["rbd"]["rbd_user"]
    storage_options["rbd_secret_uuid"] = node["cinder"]["storage"]["rbd"]["rbd_secret_uuid"]
    storage_options["glance_api_version"] = "2"
  else
    msg = "#{storage_provider}, is not currently supported by these cookbooks. Please change the storage provider attribute in your environment to one of lvm, emc, solidfire, netappiscsi, netappnfsdirect."
    Chef::Application.fatal! msg
  end

  notification_provider = node["cinder"]["notification"]["driver"]
  case notification_provider
  when "no_op"
    notification_driver = "cinder.openstack.common.notifier.no_op_notifier"
  when "rpc"
    notification_driver = "cinder.openstack.common.notifier.rpc_notifier"
  when "log"
    notification_driver = "cinder.openstack.common.notifier.log_notifier"
  else
    msg = "#{notification_provider}, is not currently supported by these cookbooks."
    Chef::Application.fatal! msg
  end

  # Get Keystone Data
  ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
  ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
  keystone = get_settings_by_role("keystone-setup", "keystone")

  # Set template for Cinder config
  t = template "/etc/cinder/cinder.conf" do
    source "cinder.conf.erb"
    owner "cinder"
    group "cinder"
    mode "0600"
    variables(
      "policy" => node["cinder"]["policy"],
      "db_ip_address" => mysql_info["host"],
      "db_user" => node["cinder"]["db"]["username"],
      "db_password" => cinder_info["db"]["password"],
      "db_name" => node["cinder"]["db"]["name"],
      "rabbit_ipaddress" => rabbit_info["host"],
      "rabbit_port" => rabbit_info["port"],
      "rabbit_ha_queues" => rabbit_settings["cluster"] ? "True" : "False",
      "notification_driver" => notification_driver,
      "notification_topics" => node["cinder"]["notification"]["topics"],
      "cinder_api_listen_ip" => cinder_api["host"],
      "cinder_api_listen_port" => cinder_api["port"],
      "storage_availability_zone" => node["cinder"]["config"]["storage_availability_zone"],
      "max_gigabytes" => node["cinder"]["config"]["max_gigabytes"],
      "storage_options" => storage_options,
      "iscsi_ip_address" => iscsi_ip_address,
      "glance_host" => glance_api["host"],
      "service_tenant_name" => node["cinder"]["service_tenant_name"],
      "service_user" => node["cinder"]["service_user"],
      "service_pass" => cinder_info["service_pass"],
      "keystone_service_api_ipaddress" => ks_service_endpoint["host"],
      "keystone_admin_api_ipaddress" => ks_admin_endpoint["host"],
      "service_port" => ks_service_endpoint["port"],
      "service_protocol" => ks_service_endpoint["scheme"],
      "admin_port" => ks_admin_endpoint["port"],
      "admin_protocol" => ks_admin_endpoint["scheme"],
      "admin_token" => keystone["admin_token"]
    )
  end
  new_resource.updated_by_last_action(t.updated_by_last_action?)
end
