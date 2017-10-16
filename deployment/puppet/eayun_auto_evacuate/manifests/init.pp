class eayun_auto_evacuate (
  $nodes               = $::fuel_settings['nodes'],
  $hostname            = $::fuel_settings['fqdn'],
  $node_role           = $::fuel_settings['role'],
  $novaclient_auth_url = "http://${::fuel_settings['management_vip']}:5000/v2.0",
  $deployment_mode     = $::fuel_settings['deployment_mode'],
){
  $roles = node_roles($::fuel_settings['nodes'], $::fuel_settings['uid'])
  if member($roles, 'controller') or member($roles, 'primary-controller') {
    $is_controller_node = true
  } else {
    $is_controller_node = false
  }
  $controllers = filter_nodes($nodes, 'role', 'controller')
  if $deployment_mode == 'multinode' {
    $storage_ip1        = $controllers[0]['storage_address']
    $deploy_controllers = [$controllers[0]['fqdn']]
    $bootstrap_expect   = 1
    $storage_ips        = [$storage_ip1]
  } elsif $deployment_mode == 'ha_compact' {
    $primary_controller = filter_nodes($nodes, 'role', 'primary-controller')
    $deploy_controllers = [$primary_controller[0]['fqdn'], $controllers[0]['fqdn'], $controllers[1]['fqdn']]
    $storage_ip1        = $primary_controller[0]['storage_address']
    $storage_ip2        = $controllers[0]['storage_address']
    $storage_ip3        = $controllers[1]['storage_address']
    $bootstrap_expect   = 3
    $storage_ips        = [$storage_ip1, $storage_ip2, $storage_ip3]
  }
  $local_ips  = filter_nodes($nodes, 'fqdn', $hostname)
  $storage_ip = $local_ips[0]['storage_address']
  
  if ($hostname in $deploy_controllers) or $node_role == 'compute' {

    package { 'consul':
      ensure => latest,
    }

    file { 'consul_config_dictory':
      ensure => directory,
      path   => '/etc/consul/storage',
    }

    file { 'consul_config_file':
      ensure  => file,
      path    => '/etc/consul/storage/consul.json',
      content => template('eayun_auto_evacuate/consul.erb'),
    }

    file { 'consul_sysconfig_file':
      ensure  => file,
      path    => '/etc/sysconfig/consul',
      content => 'CMD_OPTS="agent -config-dir=/etc/consul/storage -rejoin"',
    }

    file { 'consul_lib_dictory':
      ensure => directory,
      path   => '/var/lib/consul',
      owner  => 'consul',
      group  => 'consul',
    }

    service { 'consul':
      ensure => running,
      enable => true,
    }

    firewall { '830 consul port':
      dport  => [8300, 8301, 8302, 8400, 8500],
      proto  => 'tcp',
      action => 'accept',
    }

    Package['consul'] ->
      File['consul_config_dictory'] ->
        File['consul_config_file'] ~>
          Service['consul']

    Package['consul'] -> File['consul_sysconfig_file'] ~> Service['consul']
    Package['consul'] -> File['consul_lib_dictory'] -> Service['consul']
    Package['consul'] ~> Service['consul']

    if $hostname in $deploy_controllers {
      package { 'eayunstack-auto-evacuate':
        ensure => latest,
      }

      augeas { 'evacuate_config_file':
        context => '/files/etc/autoevacuate/evacuate.conf',
        lens    => 'Puppet.lns',
        incl    => '/etc/autoevacuate/evacuate.conf',
        changes => "set novaclient/auth_url ${novaclient_auth_url}",
      }

      service { 'eayunstack-auto-evacuate':
        ensure => running,
        enable => true,
      }

      Package['eayunstack-auto-evacuate'] ->
        Augeas['evacuate_config_file'] ~>
          Service['eayunstack-auto-evacuate']

      Package['eayunstack-auto-evacuate'] ~> Service['eayunstack-auto-evacuate']

    }

  }

}
