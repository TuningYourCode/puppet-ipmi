# == Defined resource type: ipmi::user
#
define ipmi::user (
  $password,
  $user    = 'root',
  $priv    = 4,
  $user_id = 3,
) {
  require ipmi

  validate_string($password, $user)
  validate_integer($priv)
  validate_integer($user_id)

  $privilege = case $priv {
    1: { 'CALLBACK' }
    2: { 'USER' }
    3: { 'OPERATOR' }
    4: { 'ADMINISTRATOR' }
    default: { fail('invalid privilege level specified') }
  }

  $channel = $ipmi::channel_id

  $tool = '/usr/bin/ipmitool'
  $test = '/usr/bin/test'

  exec { "ipmi_user_add_${title}":
    command => "${tool} user set name ${user_id} ${user}",
    unless  => "${test} \"$(${tool} user list ${channel} | grep '^${user_id}' | awk '{print \$2}')\" = \"${user}\"",
    notify  => [
      Exec["ipmi_user_priv_${title}"],
      Exec["ipmi_user_setpw_${title}"],
    ],
  }

  exec { "ipmi_user_priv_${title}":
    command => "${tool} user priv ${user_id} ${priv} ${channel}",
    unless  => "${test} \"$(${tool} user list ${channel} | grep '^${user_id}' | awk '{print \$6}')\" = ${privilege}",
    notify  => [
      Exec["ipmi_user_enable_${title}"],
      Exec["ipmi_user_enable_sol_${title}"],
      Exec["ipmi_user_channel_setaccess_${title}"],
    ],
  }

  exec { "ipmi_user_setpw_${title}":
    command => "${tool} user set password ${user_id} \'${password}\'",
    unless  => "${tool} user test ${user_id} 16 \'${password}\'",
    notify  => [
      Exec["ipmi_user_enable_${title}"],
      Exec["ipmi_user_enable_sol_${title}"],
      Exec["ipmi_user_channel_setaccess_${title}"],
    ],
  }

  exec { "ipmi_user_enable_${title}":
    command     => "${tool} user enable ${user_id}",
    refreshonly => true,
  }

  exec { "ipmi_user_enable_sol_${title}":
    command     => "${tool} sol payload enable ${channel} ${user_id}",
    refreshonly => true,
  }

  exec { "ipmi_user_channel_setaccess_${title}":
    command     => "${tool} channel setaccess ${channel} ${user_id} callin=on ipmi=on link=on privilege=${priv}",
    refreshonly => true,
  }
}
