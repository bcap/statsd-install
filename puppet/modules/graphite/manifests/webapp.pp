class graphite::webapp (
  $major_version = "0.9",
  $minor_version = "9",
) {
  
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $webapp_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/graphite-web-${full_version}.tar.gz"
  $webapp_package = "${build_dir}/graphite-web-${full_version}.tar.gz"

  include "graphite::whisper"

  package { "webapp-dependencies" :
    name   => [
      "python-support", 
      "python-ldap", 
      "python-cairo", 
      "python-django-tagging", 
      "python-simplejson", 
      "python-memcache", 
      "python-pysqlite2",
      "python-txamqp",
      "apache2",
      "libapache2-mod-python",
    ],
    ensure  => latest,
    require => Package["webapp-django-1.3"],
  }

  package { "webapp-django-1.3":
    name => "python-django",
    ensure => "1.3",
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

  file { "/opt/graphite/webapp/graphite/initial_data.json" :
    ensure  => present,
    source  => "puppet:///modules/graphite/webapp/initial_data.json",
    require => Exec["install-webapp"],
  }

  file { "/opt/graphite/webapp/graphite/local_settings.py" :
    source  => "puppet:///modules/graphite/webapp/local_settings.py",
    ensure  => present,
    require => Exec["install-webapp"]
  }

  file { "/etc/apache2/sites-available/default" :
    source  => "puppet:///modules/graphite/webapp/apache-default-site",
    notify  => Service["apache2"],
    require => Package["webapp-dependencies"],
  }

  file { ["/opt/graphite/storage", "/opt/graphite/storage/log/webapp"]:
    ensure    => "directory",
    owner     => "www-data",
    mode      => "0775",
    require   => Package["webapp-dependencies"],
  }

  file { "/var/log/graphite":
    ensure    => "link",
    target    => "/opt/graphite/storage/log/webapp",
    require   => Package["webapp-dependencies"],
  }

  file { "/opt/graphite/storage/whisper" :
    ensure    => link,
    force     => true,
    owner     => "www-data",
    group     => "graphite",
    target    => "/var/lib/whisper/storage",
    notify    => Service[carbon],
    subscribe => Exec["install-carbon"],
  }

  exec { "init-db":
    command   => "python manage.py syncdb --noinput",
    cwd       => "/opt/graphite/webapp/graphite",
    creates   => "/opt/graphite/storage/graphite.db",
    require   => [ File["/opt/graphite/storage/log/webapp"], File["/opt/graphite/webapp/graphite/initial_data.json"], Exec["install-webapp"] ]
  }

  file { "/opt/graphite/storage/graphite.db" :
    owner     => "www-data",
    mode      => "0664",
    subscribe => Exec["init-db"],
    notify    => Service["apache2"],
  }

  service { "apache2" :
    ensure => "running",
    require => [ File["/var/log/graphite"], File["/opt/graphite/storage/graphite.db"], File["/opt/graphite/storage/whisper"] ],
  }

}