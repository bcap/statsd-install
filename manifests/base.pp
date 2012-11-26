Exec {
  path => ["/usr/bin", "/usr/sbin", '/bin']
}

Exec["apt-get-update"] -> Package <| |>

exec { "apt-get-update" :
  command => "/usr/bin/apt-get update",
}

class statsd {

  package { "nodejs" :
    ensure => "present"
  }

  # for now
  package { "statsd" :
    provider => "dpkg",
    source => "/vagrant/statsd_0.0.1_all.deb",
    ensure => installed,
    require => Package[nodejs],
  }

}

class carbon {

  # Configs
  $major_version = "0.9"
  $minor_version = "9"

  # Vars
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $carbon_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/carbon-${full_version}.tar.gz"
  $carbon_package = "${build_dir}/carbon-${full_version}.tar.gz"

  include webapp

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
    source => "/tmp/vagrant-puppet/manifests/files/carbon",
    ensure => present
  }

  file { "/opt/graphite/conf/carbon.conf" :
    source    => "/tmp/vagrant-puppet/manifests/files/carbon.conf",
    ensure    => present,
    notify    => Service["carbon"],
    subscribe => Exec["install-carbon"],
  }

  file { "/opt/graphite/conf/storage-schemas.conf" :
    source    => "/tmp/vagrant-puppet/manifests/files/storage-schemas.conf",
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

class webapp {

  # Configs
  $major_version = "0.9"
  $minor_version = "9"

  # Vars
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $webapp_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/graphite-web-${full_version}.tar.gz"
  $webapp_package = "${build_dir}/graphite-web-${full_version}.tar.gz"

  include whisper

  package { "webapp-dependencies" :
    name   => [
      "python-support", 
      "python-ldap", 
      "python-cairo", 
      "python-django", 
      "python-django-tagging", 
      "python-simplejson", 
      "python-memcache", 
      "python-pysqlite2",
      "python-txamqp",
      "apache2",
      "libapache2-mod-python",
    ],
    ensure => latest,
  }

  exec { "download-webapp":
    command => "wget -O $webapp_package $webapp_url",
    creates => "$webapp_package"
  }

  exec { "unpack-webapp":
    command     => "tar -zxvf $webapp_package",
    cwd         => $build_dir,
    subscribe   => Exec["download-webapp"],
    refreshonly => true,
  }

  exec { "install-webapp":
    command => "python setup.py install",
    cwd     => "$build_dir/graphite-web-${full_version}",
    require => [ Exec["unpack-webapp"], Package["webapp-dependencies"], Class["whisper"] ],
    creates => "/opt/graphite/webapp"
  }

  file { [ "/opt/graphite/storage", "/opt/graphite/storage/whisper" ]:
    owner     => "www-data",
    mode      => "0775",
    subscribe => Exec["install-webapp"],
  }

  file { "/opt/graphite/webapp/graphite/initial_data.json" :
    ensure  => present,
    source  => "/tmp/vagrant-puppet/manifests/files/initial_data.json",
    require => Exec["install-webapp"],
  }

  file { "/opt/graphite/storage/log/webapp":
    ensure    => "directory",
    owner     => "www-data",
    mode      => "0775",
    subscribe => Exec["install-webapp"],
  }

  file { "/opt/graphite/webapp/graphite/local_settings.py" :
    source  => "/tmp/vagrant-puppet/manifests/files/local_settings.py",
    ensure  => present,
    require => Exec["install-webapp"]
  }

  file { "/etc/apache2/sites-available/default" :
    source  => "/tmp/vagrant-puppet/manifests/files/apache-default-site",
    notify  => Service["apache2"],
    require => Package["webapp-dependencies"],
  }

  exec { "init-db":
    command   => "python manage.py syncdb --noinput",
    cwd       => "/opt/graphite/webapp/graphite",
    creates   => "/opt/graphite/storage/graphite.db",
    subscribe => File["/opt/graphite/storage"],
    require   => [ File["/opt/graphite/webapp/graphite/initial_data.json"], Exec["install-webapp"] ]
  }

  file { "/opt/graphite/storage/graphite.db" :
    owner     => "www-data",
    mode      => "0664",
    subscribe => Exec["init-db"],
    notify    => Service["apache2"],
  }

  service { "apache2" :
    ensure => "running",
    require => [ File["/opt/graphite/storage/log/webapp"], File["/opt/graphite/storage/graphite.db"] ],
  }

}

class whisper {
  # Configs
  $major_version = "0.9"
  $minor_version = "9"

  # Vars
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $whisper_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/whisper-${full_version}.tar.gz"
  $whisper_package = "${build_dir}/whisper-${full_version}.tar.gz"

  package { "whisper-dependencies" :
    name   => ["python-txamqp"],
    ensure => latest,
  }

  exec { "download-whisper":
    command => "wget -O $whisper_package $whisper_url",
    creates => "$whisper_package"
  }

  exec { "unpack-whisper":
    command     => "tar -zxvf $whisper_package",
    cwd         => $build_dir,
    subscribe   => Exec["download-whisper"],
    refreshonly => true,
  }

  exec { "install-whisper":
    command => "python setup.py install",
    cwd     => "$build_dir/whisper-${full_version}",
    creates => "/usr/local/bin/whisper-info.py",
    require => [ Exec["unpack-whisper"], Package["whisper-dependencies"] ],
  }
}

include webapp
include carbon
include whisper
