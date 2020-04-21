# == Defined resource type: ipmi::network
#
define ipmi::network (
  Stdlib::IP::Address::V4::Nosubnet $ip      = '0.0.0.0',
  Stdlib::IP::Address::V4::Nosubnet $netmask = '255.255.255.0',
  Stdlib::IP::Address::V4::Nosubnet $gateway = '0.0.0.0',
  Enum['dhcp', 'static'] $type               = 'dhcp',
) {
  require ::ipmi

  $channel = $ipmi::params::channel

  if $type == 'dhcp' {

    exec { "ipmi_set_dhcp_${channel}":
      command => "/usr/bin/ipmitool lan set ${channel} ipsrc dhcp",
      onlyif  => "/usr/bin/test $(ipmitool lan print ${channel} | grep 'IP \
Address Source' | cut -f 2 -d : | grep -c DHCP) -eq 0",
    }
  }

  else {

    exec { "ipmi_set_static_${channel}":
      command => "/usr/bin/ipmitool lan set ${channel} ipsrc static",
      onlyif  => "/usr/bin/test $(ipmitool lan print ${channel} | grep 'IP \
Address Source' | cut -f 2 -d : | grep -c DHCP) -eq 1",
      notify  => [
        Exec["ipmi_set_ipaddr_${channel}"],
        Exec["ipmi_set_defgw_${channel}"],
        Exec["ipmi_set_netmask_${channel}"]
      ],
    }

    exec { "ipmi_set_ipaddr_${channel}":
      command => "/usr/bin/ipmitool lan set ${channel} ipaddr ${ip}",
      onlyif  => "/usr/bin/test \"$(ipmitool lan print ${channel} | grep \
'IP Address  ' | sed -e 's/.* : //g')\" != \"${ip}\"",
    }

    exec { "ipmi_set_defgw_${channel}":
      command => "/usr/bin/ipmitool lan set ${channel} defgw ipaddr ${gateway}",
      onlyif  => "/usr/bin/test \"$(ipmitool lan print ${channel} | grep \
'Default Gateway IP' | sed -e 's/.* : //g')\" != \"${gateway}\"",
    }

    exec { "ipmi_set_netmask_${channel}":
      command => "/usr/bin/ipmitool lan set ${channel} netmask ${netmask}",
      onlyif  => "/usr/bin/test \"$(ipmitool lan print ${channel} | grep \
'Subnet Mask' | sed -e 's/.* : //g')\" != \"${netmask}\"",
    }
  }
}
