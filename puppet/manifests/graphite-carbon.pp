class graphite-carbon (
  $major_version = "0.9",
  $minor_version = "9",
) {
  
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $carbon_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/carbon-${full_version}.tar.gz"
  $carbon_package = "${build_dir}/carbon-${full_version}.tar.gz"

  include graphite-webapp

  package { "carbon-dependencies":
    name   => ["python-twisted"],
    ensure => latest
  }

  exec { "download-carbon":
    command => "wget -O $carbon_package $carbon_url",
    creates => "$carbon_package"
  }

  exec { "unpack-carbon":
    command     => "tar -zxvf $carbon_package",
    cwd         => "$build_dir",
    refreshonly => true,
    subscribe   => Exec["download-carbon"],
  }

  exec { "install-carbon" :
    command => "python setup.py install",
    cwd     => "$build_dir/carbon-${full_version}",
    creates => "/opt/graphite/bin/carbon-cache.py",
    require => [ Exec["unpack-carbon"], Package["carbon-dependencies"], Class["webapp"] ]
  }

  file { "/etc/init.d/carbon" :
    source => "/tmp/vagrant-puppet/files/carbon",
    ensure => present
  }

  file { "/opt/graphite/conf/carbon.conf" :
    source    => "/tmp/vagrant-puppet/files/carbon.conf",
    ensure    => present,
    notify    => Service["carbon"],
    subscribe => Exec["install-carbon"],
  }

  file { "/opt/graphite/conf/storage-schemas.conf" :
    source    => "/tmp/vagrant-puppet/files/storage-schemas.conf",
    ensure    => present,
    notify    => Service[carbon],
    subscribe => Exec["install-carbon"],
  }

  file { "/var/log/carbon" :
    ensure => directory,
    owner  => "www-data",
    group  => "www-data",
  }

  service { "carbon" :
    ensure    => running,
    require   => [ File["/etc/init.d/carbon"], Exec["install-carbon"] ],
  }
}