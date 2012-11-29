class graphite::whisper (
  $major_version = "0.9",
  $minor_version = "9",
) {
  
  $full_version = "${major_version}.${minor_version}"
  $build_dir = "/tmp"
  $whisper_url = "http://launchpad.net/graphite/${major_version}/${full_version}/+download/whisper-${full_version}.tar.gz"
  $whisper_package = "${build_dir}/whisper-${full_version}.tar.gz"

  group { "graphite":
    ensure => present,
    system => true,
  }

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