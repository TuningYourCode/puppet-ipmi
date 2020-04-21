# == Class: ipmi::params
#
# This class should be considered private.
#
class ipmi::params {
  $channel = $facts['ipmi_channel']
  case $::osfamily {
    'redhat': {
      case $::operatingsystemmajrelease {
        '5': {
          $ipmi_package = ['OpenIPMI', 'OpenIPMI-tools']
        }
        default: {
          $ipmi_package = ['OpenIPMI', 'ipmitool']
        }
      }
      $config_location = '/etc/sysconfig/ipmi'
      $ipmi_service_name = 'ipmi'
    }
    'debian': {
      $ipmi_package = ['openipmi', 'ipmitool']
      $config_location = '/etc/default/openipmi'
      $ipmi_service_name = 'openipmi'
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

}
