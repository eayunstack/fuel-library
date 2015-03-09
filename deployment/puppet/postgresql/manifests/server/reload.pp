# PRIVATE CLASS: do not use directly
class postgresql::server::reload {
  $service_name   = $postgresql::server::service_name
  $service_status = $postgresql::server::service_status

  if $::is_virtual == 'true' and $::virtual =~ /docker/ and $::operatingsystemmajrelease >= 7 {
    exec { 'postgresql_reload':
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      command     => 'su - postgres -c "export PGDATA=/var/lib/pgsql/data;/usr/bin/pg_ctl reload -D \${PGDATA} -s',
      onlyif      => $service_status,
      refreshonly => true,
      require     => Class['postgresql::server::service'],
    }
  } else {
    exec { 'postgresql_reload':
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      command     => "service ${service_name} reload",
      onlyif      => $service_status,
      refreshonly => true,
      require     => Class['postgresql::server::service'],
    }
  }
}
