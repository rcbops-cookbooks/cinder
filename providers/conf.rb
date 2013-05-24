action :create do
  log "Creating cinder.conf"

  platform_options = node["cinder"]["platform"]

  # Search for rabbitmq endpoint info
  rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
  # Search for mysql endpoint info
  mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
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


  # Currently we support SolidFire, EMC VMAX/VNX, NetApp ISCSI (onCommand), and NetApp NFSDirect
  storage_provider = node["cinder"]["storage"]["provider"]
  storage_options = {}
  case storage_provider
  when "solidfire"
	  storage_options["volume_driver"] = "cinder.volume.solidfire.SolidFire"
	  storage_options["san_ip"] = node["cinder"]["storage"]["provider"][storage_provider]["mvip"]
	  storage_options["san_login"] = node["cinder"]["storage"]["provider"][storage_provider]["username"]
	  storage_options["san_password"] = node["cinder"]["storage"]["provider"][storage_provider]["password"]
  when "netappiscsi"
	  storage_options["volume_driver"] = "cinder.volume.netapp.NetAppISCSIDriver"
	  storage_options["netapp_wsdl_url"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["wsdl_url"]
	  storage_options["netapp_login"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["login"]
	  storage_options["netapp_password"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["password"]
	  storage_options["netapp_server_hostname"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["server_hostname"]
	  storage_options["netapp_server_port"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["server_port"]
	  storage_options["netapp_storage_service"] = node["cinder"]["storage"]["provider"]["netapp"]["iscsi"]["storage_service"]
  when "netappnfsdirect"
	  storage_options["volume_driver"] = "cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver"
          storage_options["netapp_server_hostname"] = node["cinder"]["storage"]["provider"]["netapp"]["nfsdirect"]["server_hostname"]
          storage_options["netapp_server_port"] = node["cinder"]["storage"]["provider"]["netapp"]["nfsdirect"]["port"]
          storage_options["netapp_login"] = node["cinder"]["storage"]["provider"]["netapp"]["nfsdirect"]["login"]
          storage_options["netapp_password"] = node["cinder"]["storage"]["provider"]["netapp"]["nfsdirect"]["password"]
          storage_options["netapp_transport_type"] = node["cinder"]["storage"]["provider"]["netapp"]["nfsdirect"]["transport_type"]
  when "emc"
	  storage_options["iscsi_target_prefix"] = "iqn.1992-04.com.emc"
	  storage_options["volume_driver"] = "cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver"
	  storage_options["cinder_emc_config_file"] = "/etc/cinder/cinder_emc_config.xml"

  end
  t = template "/etc/cinder/cinder.conf" do
	  source "cinder.conf.erb"
	  owner "cinder"
	  group "cinder"
	  mode "0600" 
	  variables(
                     "db_ip_address" => mysql_info["host"],
                     "db_user" => node["cinder"]["db"]["username"],
                     "db_password" => cinder_info["db"]["password"],
                     "db_name" => node["cinder"]["db"]["name"],
                     "rabbit_ipaddress" => rabbit_info["host"],
                     "rabbit_port" => rabbit_info["port"],
                     "cinder_api_listen_ip" => cinder_api["host"],
                     "cinder_api_listen_port" => cinder_api["port"],
                     "storage_availability_zone" => node["cinder"]["config"]["storage_availability_zone"],
		     "storage_options" => storage_options,
                     "iscsi_ip_address" => iscsi_ip_address
          )
  end
  new_resource.updated_by_last_action(t.updated_by_last_action?)
end
