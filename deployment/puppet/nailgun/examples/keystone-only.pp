$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and $::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

package { 'python-psycopg2':
  ensure => installed,
}

case $production {
  'prod', 'docker': {

    class {'docker::container': }

    class { 'keystone':
      admin_token      => $::fuel_settings['keystone']['admin_token'],
      catalog_type     => 'sql',
      sql_connection   => "postgresql://${::fuel_settings['postgres']['keystone_user']}:${::fuel_settings['postgres']['keystone_password']}@${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/${::fuel_settings['postgres']['keystone_dbname']}",
      token_expiration => 86400,
      token_provider   => 'keystone.token.providers.uuid.Provider',
    }

    #FIXME(mattymo): We should enable db_sync on every run inside keystone,
    #but this is related to a larger scope fix for concurrent deployment of
    #secondary controllers.
    Exec <| title == 'keystone-manage db_sync' |> {
      refreshonly => false,
    }

    # Admin user
    keystone_tenant { 'admin':
      ensure  => present,
      enabled => 'True',
    }

    keystone_tenant { 'services':
      ensure      => present,
      enabled     => 'True',
      description => 'fuel services tenant',
    }

    keystone_role { 'admin':
      ensure => present,
    }

    keystone_user { 'admin':
      ensure          => present,
      password        => $::fuel_settings['FUEL_ACCESS']['password'],
      enabled         => 'True',
      tenant          => 'admin',
      manage_password => 'False',
    }

    keystone_user_role { 'admin@admin':
      ensure => present,
      roles  => ['admin'],
    }

    # user for eayuncenter for api call
    keystone_user { 'eayunadm':
      ensure          => present,
      password        => $::fuel_settings['keystone']['nailgun_password'],
      enabled         => 'True',
      tenant          => 'admin',
      manage_password => 'False',
    }

    keystone_user_role { 'eayunadm@admin':
      ensure => present,
      roles  => ['admin'],
    }

    # Keystone Endpoint
    class { 'keystone::endpoint':
      public_address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
      admin_address    => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
      internal_address => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    }

    # Nailgun
    class { 'nailgun::auth':
      auth_name => $::fuel_settings['keystone']['nailgun_user'],
      password  => $::fuel_settings['keystone']['nailgun_password'],
      address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    }

    # OSTF
    class { 'nailgun::ostf::auth':
      auth_name => $::fuel_settings['keystone']['ostf_user'],
      password  => $::fuel_settings['keystone']['ostf_password'],
      address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    }

    package { 'crontabs':
      ensure => latest,
    }

    if $::is_virtual == 'true' and $::virtual =~ /docker/ {
      service { 'crond':
        ensure    => running,
        hasstatus => false,
        start     => 'if [ -e /etc/sysconfig/crond ]; then source /etc/sysconfig/crond; fi; /usr/sbin/crond $CRONDARGS',
        binary    => '/usr/sbin/crond',
        provider  => 'base',
      }
    } else {
      service { 'crond':
        ensure => running,
        enable => true,
      }
    }

    # Flush expired tokens
    cron { 'keystone-flush-token':
      ensure      => present,
      command     => 'keystone-manage token_flush',
      environment => 'PATH=/bin:/usr/bin:/usr/sbin',
      user        => 'root',
      hour        => '1',
      require     => Package['crontabs'],
    }
  }
  'docker-build': {
  }
}
