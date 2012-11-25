Vagrant::Config.run do |config|
  config.vm.box = "ubuntu11.04_puppet"
  config.vm.box_url = "https://github.com/downloads/divio/vagrant-boxes/vagrant-ubuntu-11.04-server-amd64-v1.box"

  config.vm.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  
  config.vm.forward_port 80, 8080
  config.vm.forward_port 2003, 2003
  config.vm.forward_port 8125, 8125, { :protocol => 'udp' }

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "base.pp"
  end
end
