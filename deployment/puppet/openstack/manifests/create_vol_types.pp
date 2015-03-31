# == Class: openstack::create_vol_types
#
# Creates Cinder Multibackend vol types.
#
# === Parameters
#
# [*set_type*]
#   (required) volume type to be created.
# [*set_key*]
#   (required) set_key
# [*set_value*]
#   (required) set_value

include cinder::params

class openstack::create_vol_types(
  $set_type,
  $set_key,
  $set_value,
) {
    $os_username = $::fuel_settings['access']['user']
    $os_password = $::fuel_settings['access']['password']
    $os_tenant_name = $::fuel_settings['access']['tenant']
    $os_auth_url = "http://${::fuel_settings['management_vip']}:5000/v2.0/"

    $primary_controller = $::fuel_settings['role'] ? { 'primary-controller'=>true, default=>false }

    if $primary_controller {

    exec {"waiting for cinder service":
      path        => '/usr/bin',
      command	  => "bash -c 'for i in {1..10}; do cinder --retries 10 type-list && break; sleep 1; done'",
      environment => [
        "OS_TENANT_NAME=${os_tenant_name}",
        "OS_USERNAME=${os_username}",
        "OS_PASSWORD=${os_password}",
        "OS_AUTH_URL=${os_auth_url}",
      ],
      require     => Package['python-cinderclient']
    } ->
    cinder::type{ $set_type:
      os_username     => $os_username,
      os_password     => $os_password,
      os_tenant_name  => $os_tenant_name,
      os_auth_url     => $os_auth_url,
      set_key         => $set_key,
      set_value       => $set_value,
      }
    }

}
