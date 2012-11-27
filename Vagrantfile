Vagrant::Config.run do |config|

  # This Vagrant configuration is based on the plain Ubuntu Server 64 12.04 iso
  # The box can be installed running the 'install-vagrant-box.sh' script
  config.vm.box = "ubuntu-precise64" 
  
  config.vm.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  
  config.vm.forward_port 80,   8080
  config.vm.forward_port 2003, 2003
  config.vm.forward_port 8125, 8125, { :protocol => 'udp' }

  config.vm.provision :puppet do |puppet|
    puppet.module_path    = "puppet/modules"
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "base.pp"
  end
end
