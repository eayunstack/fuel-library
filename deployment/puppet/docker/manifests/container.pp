class docker::container (
$tz           = 'Asia/Shanghai',
$zoneinfo_dir = '/usr/share/zoneinfo',
) {

  if $tz != false {
    file { '/etc/localtime':
      ensure => present,
      target => "${zoneinfo_dir}/${tz}"
    }
  }

}
