# == Defined resource type: ipmi::user
#
define ipmi::user (
  Integer[1, default] $id,
  Enum[present, absent] $ensure = present,
  String $username              = $title,
  Optional[String] $password    = undef,
  Integer[1, 4] $priv           = 4,
) {
  require ipmi

  $priv_text = case $priv {
    1: { 'CALLBACK' }
    2: { 'USER' }
    3: { 'OPERATOR' }
    4: { 'ADMINISTRATOR' }
    default: { fail('invalid privilege level specified') }
  }

  $channel = $ipmi::channel_id

  $tool = '/usr/bin/ipmitool'

  if $ensure == present {

    exec { "ipmi_user_add_${title}":
      command => "${tool} user set name ${id} ${username}",
      unless  => "${tool} channel getaccess ${channel} ${id} | grep '^User Name.*${username}$'",
    }

    $refresh_execs = [
      Exec["ipmi_user_enable_sol_${title}"],
    ]

    exec { "ipmi_user_priv_${title}":
      command => "${tool} channel setaccess ${channel} ${id} callin=on ipmi=on link=on privilege=${priv}",
      unless  => "${tool} channel getaccess ${channel} ${id} | grep '^Privilege Level.*${priv_text}$'",
      require => Exec["ipmi_user_add_${title}"],
      notify  => $refresh_execs,
    }

    if $password {
      exec { "ipmi_user_setpw_${title}":
        command => "${tool} user set password ${id} \'${password}\'",
        unless  => "${tool} user test ${id} 16 \'${password}\'",
        require => Exec["ipmi_user_add_${title}"],
        notify  => $refresh_execs,
      }
    }

    exec { "ipmi_user_enable_${title}":
      command => "${tool} user enable ${id}",
      unless  => "${tool} channel getaccess ${channel} ${id} | grep '^Enable Status.*enabled$'",
      require => Exec["ipmi_user_add_${title}"],
      notify  => $refresh_execs,
    }

    exec { "ipmi_user_enable_sol_${title}":
      command     => "${tool} sol payload enable ${channel} ${id}",
      refreshonly => true,
    }

  } else {

    exec { "ipmi_user_disable_${title}":
      command => "${tool} user disable ${id}",
      unless  => "${tool} channel getaccess ${channel} ${id} | grep '^Enable Status.*disabled$'",
    }

  }

}
