# == Class: ipmi
#
# Please refer to https://github.com/jhoblitt/puppet-ipmi#usage for
# parameter documentation.
#
class ipmi (
  Enum[present, absent] $ensure                  = present,
  Enum[running, stopped] $ipmievd_service_ensure = stopped,
  Boolean $watchdog                              = false,
  Hash $users                                    = {},
  Boolean $purge_users                           = false,
  Boolean $foreman_user                          = false,
  Integer[1, 4] $foreman_user_privilege          = 4,
  Hash $networks                                 = {},
  Hash $snmps                                    = {},
) inherits ipmi::params {

  if $ensure == present {

    $watchdog_str = $watchdog ? {
      true    => 'yes',
      default => 'no',
    }

    package { $ipmi::params::ipmi_package:
      ensure => present,
    }
    ~> augeas { $ipmi::params::config_location:
      context => "/files${ipmi::params::config_location}",
      changes => "set IPMI_WATCHDOG ${watchdog_str}",
    }
    ~> service { $ipmi::params::ipmi_service_name:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
    ~> service { 'ipmievd':
      ensure     => $ipmievd_service_ensure,
      enable     => $ipmievd_service_ensure == running,
      hasstatus  => true,
      hasrestart => true,
    }

    $foreman_bmc = if $foreman_user and $::foreman_interfaces {
      $foreman_bmcs = $::foreman_interfaces.filter |$interface| {
        $interface['type'] == 'BMC' and !empty($interface['username'])
      }
      $foreman_bmcs[0]
    } else {
      undef
    }
    $users_foreman = if $foreman_bmc and 'ipmi_users' in $facts {
      $existing_user = $facts['ipmi_users'].filter |$user| {
        $user['username'] == $foreman_bmc['username']
      }[0]
      $id = if $existing_user {
        $existing_user['id']
      } else {
        $facts['ipmi_users'].map |$user| { $user['id'] }.max + 1
      }
      $base_hash = {
        id        => $id,
        privilege => $foreman_user_privilege,
      }
      $password_hash = if !empty($foreman_bmc['password']) {
        { password => $foreman_bmc['password'] }
      } else {
        {}
      }
      Hash([$foreman_bmc['username'], $base_hash + $password_hash])
    } else {
      {}
    }

    $users_present = $users + $users_foreman

    $users_absent = if $purge_users and 'ipmi_users' in $facts {
      $present_ids = $users_present.map |$name, $params| { $params['id'] }
      $enabled_ids = $facts['ipmi_users'].filter |$user| { $user['enabled'] }.map |$user| { $user['id'] }
      $extraneous_ids = $enabled_ids - $present_ids
      Hash($extraneous_ids.map |$id| { ["id_${id}", {
        id     => $id,
        ensure => absent,
      }] })
    } else {
      {}
    }

    create_resources('ipmi::user', $users_present + $users_absent)
    create_resources('ipmi::snmp', $snmps)
    create_resources('ipmi::network', $networks)

  } else {

    package { $ipmi::params::ipmi_package:
      ensure => absent,
    }

  }

}
