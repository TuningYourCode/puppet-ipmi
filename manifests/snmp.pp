# == Defined resource type: ipmi::snmp
#
define ipmi::snmp (
  String $snmp = 'public',
) {
  require ipmi

  $channel = $ipmi::params::channel

  exec { "ipmi_set_snmp_${channel}":
    command => "/usr/bin/ipmitool lan set ${channel} snmp ${snmp}",
    onlyif  => "/usr/bin/test \"$(ipmitool lan print ${channel}
         | grep 'SNMP Community String' | sed -e 's/.* : //g')\" != \"${snmp}\"",
  }
}
