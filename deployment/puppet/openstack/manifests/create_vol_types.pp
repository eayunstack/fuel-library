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
  $ha_mode,
) {
    $os_username = $::fuel_settings['access']['user']
    $os_password = $::fuel_settings['access']['password']
    $os_tenant_name = $::fuel_settings['access']['tenant']
    $os_auth_url = "http://${::fuel_settings['management_vip']}:5000/v2.0/"

    if $ha_mode {
      $primary_controller = $::fuel_settings['role'] ? { 'primary-controller'=>true, default=>false }
    }
    else {
      $primary_controller = true
    }

    if $primary_controller {
      exec {"waiting for cinder service":
        path        => '/usr/bin',
        command     => 'cinder --retries 10 type-list',
        tries       => 10,
        try_sleep   => 1,
        timeout     => 600,
        environment => [
          "OS_TENANT_NAME=${os_tenant_name}",
          "OS_USERNAME=${os_username}",
          "OS_PASSWORD=${os_password}",
          "OS_AUTH_URL=${os_auth_url}",
        ],
        require     => [
                        Package['python-cinderclient'],
                        Class['openstack::cinder'],
                        Class['cinder::keystone::auth'],
                        ],
      } ->
      cinder::type { $set_type:
        os_username     => $os_username,
        os_password     => $os_password,
        os_tenant_name  => $os_tenant_name,
        os_auth_url     => $os_auth_url,
        set_key         => $set_key,
        set_value       => $set_value,
      }

      if $ha_mode {
         Exec['haproxy reload for cinder-api'] ->
          Exec['waiting for cinder service']
      }
    }
  }
