# == Class: ipmi
#
# Please refer to https://github.com/jhoblitt/puppet-ipmi#usage for
# parameter documentation.
#
class ipmi (
  Enum[present, absent] $ensure                  = present,
  Enum[running, stopped] $ipmievd_service_ensure = stopped,
  Boolean $watchdog                              = false,
  Array[Hash] $users                             = [],
  Boolean $purge_users                           = false,
  Variant[Boolean, Enum[optional]] $foreman_user = false,
  Integer[1, 4] $foreman_user_privilege          = 4,
  Optional[Hash] $network                        = undef,
  Optional[String] $snmp                         = undef,
) {

  include ipmi::params

  if $ensure == present {

    $watchdog_str = if $watchdog { 'yes' } else { 'no' }
    $channel = $ipmi::params::channel

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

    Service[$ipmi::params::ipmi_service_name] -> Ipmi::User <| |>
    Service[$ipmi::params::ipmi_service_name] -> Ipmi::Network <| |>
    Service[$ipmi::params::ipmi_service_name] -> Ipmi::Snmp <| |>

    $foreman_bmc = if $foreman_user {
      if !$::foreman_interfaces {
        fail("foreman_user set but 'foreman_interfaces' not passed from Foreman ENC")
      }
      if !('ipmi_macaddress' in $facts) {
        warning(join([
          "foreman_user set but missing 'ipmi_macaddress' fact, ",
          "assuming this is first run and wasn't installed before facts gneerated, not adding Foreman user",
        ]))
        ; undef
      } else {
        $foreman_bmcs = $::foreman_interfaces.filter |$interface| {
          $interface['type'] == 'BMC' and $interface['mac'] == $facts['ipmi_macaddress']
        }
        if empty($foreman_bmcs) {
          if $foreman_user == true {
            fail("No BMC interface matching ${$facts['ipmi_macaddress']} in Foreman host but foreman_user requires it")
          }
          ; undef
        } elsif empty($foreman_bmcs[0]['username']) {
          if $foreman_user == true {
            fail('No username on BMC interface specified in Foreman host but foreman_user requires it')
          }
          ; undef
        } elsif empty($foreman_bmcs[0]['password']) {
          if $foreman_user == true {
            fail('No password on BMC interface specified in Foreman host but foreman_user requires it')
          }
          ; undef
        } else {
          $foreman_bmcs[0]
        }
      }
    } else {
      undef
    }
    $foreman_users = if $foreman_bmc {
      [{
        username  => $foreman_bmc['username'],
        password  => $foreman_bmc['password'],
        privilege => $foreman_user_privilege,
      }]
    } else {
      []
    }

    $users_existing_ids_applied = ($users + $foreman_users).map |$user| {
      if $user['id'] or !('ipmi_users' in $facts) {
        $user
      } else {
        $existing_user = $facts['ipmi_users'].filter |$existing_user| {
          $user['username'] == $existing_user['username']
        }[0]
        if $existing_user {
          $user + { id => $existing_user['id'] }
        } else {
          $user
        }
      }
    }

    $users_with_id = $users_existing_ids_applied.filter |$user| { 'id' in $user }
    $users_without_id = $users_existing_ids_applied.filter |$user| { !('id' in $user) }

    $users_allocated_new_ids = if 'ipmi_users' in $facts and 'ipmi_max_users' in $facts {
      $existing_ids = $facts['ipmi_users'].map |$user| { $user['id'] }
      $passed_ids = $users.map | $user | { $user['id'] }
      $all_possible_ids = Integer[1, $facts['ipmi_max_users']].map |$i| { $i }
      $available_ids = $all_possible_ids - $existing_ids - $passed_ids
      $users_without_id.map |$i, $user| {
        if $user[ensure] in [absent, disabled] {
          fail("Can't have user ensure => ${$user[ensure]} when no id specified")
        }
        $id = $available_ids[$i]
        if !$id {
          fail("Max users is ${$facts['ipmi_max_users']} and all ids are taken")
        }
        $user + { id => $id }
      }
    } else {
      if !empty($users_without_id) {
        warning(join([
          "users without ids but missing 'ipmi_*' facts,",
          "assuming this is first run and wasn't installed before facts gneerated, not adding Foreman user",
        ]))
      }
      ; []
    }

    $users_wanted = $users_with_id + $users_allocated_new_ids

    $users_remove = if $purge_users {
      if !('ipmi_users' in $facts) {
        warning(join([
          "purge_users set but no 'ipmi_users' fact, ",
          "assuming this is first run and wasn't installed before facts gneerated, not purging",
        ]))
        ; []
      } else {
        $present_ids = $users_wanted.map |$params| { $params['id'] }
        $existing_enabled_ids = $facts['ipmi_users'].filter |$user| { $user['enabled'] }.map |$user| { $user['id'] }
        $extraneous_ids = $existing_enabled_ids - $present_ids
        $extraneous_ids.map |$id| {
          {
            id     => $id,
            ensure => absent,
          }
        }
      }
    } else {
      []
    }

    $users_hash = Hash(($users_wanted + $users_remove).map |$user| {
      $id = $user['id']
      ["id_${id}", $user + { channel => $channel }]
    })

    create_resources('ipmi::user',
      $users_hash,
    )

    if $network {
      ipmi::network { 'init':
        *       => $network,
        channel => $channel,
      }
    }

    if $snmp {
      ipmi::snmp { 'init':
        snmp    => $snmp,
        channel => $channel,
      }
    }

  } else {

    package { $ipmi::params::ipmi_package:
      ensure => absent,
    }

  }

}
