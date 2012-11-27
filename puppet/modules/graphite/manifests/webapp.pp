class graphite::webapp (
  $major_version = "0.9",
  $minor_version = "9",
) {
  
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $webapp_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/graphite-web-${full_version}.tar.gz"
  $webapp_package = "${build_dir}/graphite-web-${full_version}.tar.gz"

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
    require => [ Exec["unpack-webapp"], Package["webapp-dependencies"] ],
    creates => "/opt/graphite/webapp"
  }

  file { [ "/opt/graphite/storage", "/opt/graphite/storage/whisper" ]:
    owner     => "www-data",
    mode      => "0775",
    subscribe => Exec["install-webapp"],
  }

  file { "/opt/graphite/webapp/graphite/initial_data.json" :
    ensure  => present,
    source  => "/tmp/vagrant-puppet/files/initial_data.json",
    require => Exec["install-webapp"],
  }

  file { "/opt/graphite/storage/log/webapp":
    ensure    => "directory",
    owner     => "www-data",
    mode      => "0775",
    subscribe => Exec["install-webapp"],
  }

  file { "/opt/graphite/webapp/graphite/local_settings.py" :
    source  => "/tmp/vagrant-puppet/files/local_settings.py",
    ensure  => present,
    require => Exec["install-webapp"]
  }

  file { "/etc/apache2/sites-available/default" :
    source  => "/tmp/vagrant-puppet/files/apache-default-site",
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