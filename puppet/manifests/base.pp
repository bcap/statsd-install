Exec {
  path => ["/usr/bin", "/usr/sbin", '/bin']
}

Exec["apt-get-update"] -> Package <| |>

exec { "apt-get-update" :
  command => "/usr/bin/apt-get update",
}

include graphite
include statsd
