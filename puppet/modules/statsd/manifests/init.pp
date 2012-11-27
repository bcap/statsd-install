class statsd  (
  $version = "0.5.0",
) {
  
  $build_dir = "/tmp"
  $statsd_url = "https://github.com/etsy/statsd/archive/v${version}.tar.gz"
  $statsd_package = "${build_dir}/statsd-v${version}.tar.gz"

  package { "statsd-dependencies":
    name   => "nodejs",
    ensure => latest
  }

  group { "statsd":
    ensure => present,
    system => true,
  }

  user { "statsd" :
    ensure  => present,
    comment => "statsd daemon system user",
    home    => "/opt/statsd",
    gid     => "statsd",
    system  => true,
    require => Group["statsd"],
  }

  exec { "download-statsd":
    command => "wget -O $statsd_package $statsd_url",
    creates => "$statsd_package"
  }

  exec { "unpack-statsd":
    command     => "tar -zxvf $statsd_package",
    cwd         => "$build_dir",
    refreshonly => true,
    subscribe   => Exec["download-statsd"],
  }

  exec { "install-statsd" :
    command => "cp -r $build_dir/statsd-${version} /opt/statsd && chown -R statsd:statsd /opt/statsd",
    creates => "/opt/statsd",
    require => [ Exec["unpack-statsd"], Package["statsd-dependencies"], User["statsd"] ]
  }

  file { "/var/log/statsd" :
    ensure  => directory,
    owner   => "statsd",
    group   => "statsd",
    require => User["statsd"],
  }

  file { "/var/run/statsd" :
    ensure  => directory,
    owner   => "statsd",
    group   => "statsd",
    require => User["statsd"],
  }

  file { "/etc/init.d/statsd" :
    source => "puppet:///modules/statsd/statsd",
    ensure => present
  }

  file { "/etc/statsd" :
    ensure  => directory,
  }

  file { "/etc/statsd/statsd-config.js" :
    source    => "puppet:///modules/statsd/statsd-config.js",
    ensure    => present,
    notify    => Service["statsd"],
    subscribe => File["/etc/statsd"],
  }

  service { "statsd" :
    ensure    => running,
    require   => [ File["/etc/init.d/statsd"], Exec["install-statsd"] ],
  }
}