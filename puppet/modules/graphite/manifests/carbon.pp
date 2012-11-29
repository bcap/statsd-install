class graphite::carbon (
  $major_version = "0.9",
  $minor_version = "9",
) {
  
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $carbon_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/carbon-${full_version}.tar.gz"
  $carbon_package = "${build_dir}/carbon-${full_version}.tar.gz"

  include "graphite::whisper"

  package { "carbon-dependencies":
    name   => ["python-twisted"],
    ensure => latest
  }

  user { "carbon" :
    ensure  => present,
    comment => "carbon daemon system user",
    home    => "/opt/carbon",
    gid     => "graphite",
    system  => true,
    require => Group["graphite"],
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

  file { "carbon-install-config":
    path    => "$build_dir/carbon-${full_version}/setup.cfg",
    source  => "puppet:///modules/graphite/carbon/setup.cfg",
    ensure  => present,
    require => Exec["unpack-carbon"],
  }

  exec { "install-carbon" :
    command => "python setup.py install && chown carbon:graphite -R /opt/carbon",
    cwd     => "$build_dir/carbon-${full_version}",
    creates => "/opt/carbon/bin/carbon-cache.py",
    require => [ Exec["unpack-carbon"], File["carbon-install-config"], User["carbon"], Package["carbon-dependencies"], Class["graphite::whisper"] ]
  }

  file { "/etc/init.d/carbon" :
    source => "puppet:///modules/graphite/carbon/carbon",
    owner  => "root",
    group  => "root",
    ensure => present
  }

  file { "/opt/carbon/conf/carbon.conf" :
    source    => "puppet:///modules/graphite/carbon/carbon.conf",
    owner     => "carbon",
    group     => "graphite",
    ensure    => present,
    notify    => Service["carbon"],
    subscribe => Exec["install-carbon"],
  }

  file { "/opt/carbon/conf/storage-schemas.conf" :
    source    => "puppet:///modules/graphite/carbon/storage-schemas.conf",
    owner     => "carbon",
    group     => "graphite",
    ensure    => present,
    notify    => Service[carbon],
    subscribe => Exec["install-carbon"],
  }

  file { "/var/run/carbon" :
    ensure  => directory,
    owner   => "carbon",
    group   => "graphite",
    require => User["carbon"],
  }

  file { "/var/log/carbon" :
    ensure => directory,
    owner  => "carbon",
    group  => "graphite",
    require => User["carbon"],
  }

  service { "carbon" :
    ensure    => running,
    require   => [ File["/etc/init.d/carbon"], Exec["install-carbon"] ],
  }
}