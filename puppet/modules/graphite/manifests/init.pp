class graphite (
  $major_version = "0.9",
  $minor_version = "9",
){
  class { "graphite::carbon": 
    major_version => $major_version,
    minor_version => $minor_version,
  }

  class { "graphite::webapp": 
    major_version => $major_version,
    minor_version => $minor_version,
  }
}