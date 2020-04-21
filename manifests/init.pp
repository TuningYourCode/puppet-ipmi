# == Class: ipmi
#
# Please refer to https://github.com/jhoblitt/puppet-ipmi#usage for
# parameter documentation.
#
class ipmi (
  Enum[present, absent] $ensure                  = present,
  Enum[running, stopped] $ipmievd_service_ensure = stopped,
  Boolean $watchdog                              = false,
  Hash $snmps                                    = {},
  Hash $users                                    = {},
  Boolean $purge_users                           = false,
  Boolean $foreman_user                          = false,
  Hash $networks                                 = {},
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

    if $snmps {
      create_resources('ipmi::snmp', $snmps)
    }

    if $users {
      create_resources('ipmi::user', $users)
    }

    if $networks {
      create_resources('ipmi::network', $networks)
    }

  } else {

    package { $ipmi::params::ipmi_package:
      ensure => absent,
    }

  }

}
