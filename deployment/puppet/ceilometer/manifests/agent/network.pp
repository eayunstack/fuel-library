# Installs/configures the ceilometer network agent
#
# == Parameters
#  [*enabled*]
#    Should the service be enabled. Optional. Defauls to true
#
class ceilometer::agent::network (
  $enabled          = true,
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-network']

  Package['ceilometer-agent-network'] -> Service['ceilometer-agent-network']
  package { 'ceilometer-agent-network':
    ensure => installed,
    name   => $::ceilometer::params::agent_network_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-agent-network']
  service { 'ceilometer-agent-network':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_network_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

}
