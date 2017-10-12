# HA configuration for OpenStack Ceilometer
class openstack::ha::ceilometer {

  openstack::ha::haproxy_service { 'ceilometer':
    order           => '140',
    listen_port     => 8777,
    public          => true,
    require_service => 'ceilometer-api',
    haproxy_config_options => {
        'option' => ['tcpka', 'httpclose','tcplog'],
        'timeout client' => '5h',
        'timeout server' => '5h',
        'balance'        => 'roundrobin',
    },
    balancermember_options => 'check inter 2000 rise 2 fall 5',
  }

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['ceilometer-api']
}
