require 'spec_helper'

describe 'ipmi', type: :class do
  describe 'for osfamily RedHat' do
    let :facts do
      {
        osfamily:                  'RedHat',
        operatingsystemmajrelease: '6',
      }
    end

    describe 'no params' do
      it do
        is_expected.to create_class('ipmi')
        is_expected.to contain_augeas('/etc/sysconfig/ipmi').with(context: '/files/etc/sysconfig/ipmi',
                                                                  changes: 'set IPMI_WATCHDOG no')
        is_expected.to contain_package('OpenIPMI').with_ensure('present')
        is_expected.to contain_package('ipmitool').with_ensure('present')
        is_expected.to contain_service('ipmi').with(ensure: 'running', enable: true)
        is_expected.to contain_service('ipmievd').with(ensure: 'stopped', enable: false)
      end
    end

    describe 'ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it do
        is_expected.to contain_package('OpenIPMI').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { { ipmievd_service_ensure: 'running' } }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running', enable: true)
      end
    end

    describe 'watchdog => true' do
      let(:params) { { watchdog: true } }

      it do
        is_expected.to contain_augeas('/etc/sysconfig/ipmi').with(context: '/files/etc/sysconfig/ipmi',
                                                                  changes: 'set IPMI_WATCHDOG yes')
      end
    end
  end

  describe 'for osfamily Debian' do
    let :facts do
      {
        osfamily: 'Debian',
      }
    end

    describe 'no params' do
      it do
        is_expected.to create_class('ipmi')
        is_expected.to contain_augeas('/etc/default/openipmi').with(context: '/files/etc/default/openipmi',
                                                                    changes: 'set IPMI_WATCHDOG no')
        is_expected.to contain_package('openipmi').with_ensure('present')
        is_expected.to contain_package('ipmitool').with_ensure('present')
        is_expected.to contain_service('openipmi').with(ensure: 'running', enable: true)
        is_expected.to contain_service('ipmievd').with(ensure: 'stopped', enable: false)
      end
    end

    describe 'ensure => absent' do
      let(:params) { { ensure: 'absent' } }

      it do
        is_expected.to contain_package('openipmi').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { { ipmievd_service_ensure: 'running' } }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running', enable: true)
      end
    end

    describe 'watchdog => true' do
      let(:params) { { watchdog: true } }

      it do
        is_expected.to contain_augeas('/etc/default/openipmi').with(context: '/files/etc/default/openipmi',
                                                                    changes: 'set IPMI_WATCHDOG yes')
      end
    end
  end

  describe 'users' do
    let :facts do
      {
        osfamily:        'Debian',
        ipmi_macaddress: 'ac:1f:6b:7f:d4:ce',
        ipmi_max_users:  10,
        ipmi_users:      [
                           {
                             'id'         => 1,
                             'username'   => '',
                             'fixed_name' => true,
                             'enabled'    => false,
                           },
                           {
                             'id'         => 2,
                             'username'   => 'ADMIN',
                             'fixed_name' => true,
                             'enabled'    => true,
                             'priv'       => 4,
                           },
                         ],
      }
    end

    describe 'with ids specified' do
      let(:params) do
        {
          'users' => [
            { 'id' => 2, 'username' => 'ADMIN', 'password' => 'secret' },
            { 'id' => 3, 'username' => 'other', 'privilege' => 1 },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(id:       2,
                                                       username: 'ADMIN',
                                                       password: 'secret',
                                                       channel:  1)
        is_expected.to contain_ipmi__user('id_3').with(id:        3,
                                                       username:  'other',
                                                       privilege: 1,
                                                       channel:   1)
      end
    end

    describe 'use id from existing user matching name' do
      let(:params) do
        {
          'users' => [
            { 'username' => 'ADMIN', 'password' => 'secret' },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(id:       2,
                                                       username: 'ADMIN',
                                                       password: 'secret',
                                                       channel:  1)
      end
    end

    describe 'noop user when no ipmi_* facts' do
      let :facts do
        {
          osfamily: 'Debian',
        }
      end
      let(:params) do
        {
          'users' => [
            { 'username' => 'ADMIN', 'password' => 'secret' },
            { 'id' => 3, 'username' => 'other', 'privilege' => 1 },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_3')
        is_expected.to have_ipmi__user_resource_count(1)
      end
    end

    describe 'allocate new ids when no names match' do
      let(:params) do
        {
          'users' => [
            { 'username' => 'other1', 'password' => 'secret1' },
            { 'username' => 'other2', 'password' => 'secret2' },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_3').with(id:       3,
                                                       username: 'other1',
                                                       password: 'secret1',
                                                       channel:  1)
        is_expected.to contain_ipmi__user('id_4').with(id:       4,
                                                       username: 'other2',
                                                       password: 'secret2',
                                                       channel:  1)
      end
    end

    describe 'fail when need to generate id but ensure => absent' do
      let(:params) do
        {
          'users' => [
            { 'username' => 'other', 'password' => 'secret', 'ensure' => 'absent' },
          ],
        }
      end

      it do
        is_expected.to compile.and_raise_error(%r{Can't have user ensure => absent when no id specified})
      end
    end

    describe 'fail when no more ids available' do
      let(:facts) do
        super().merge(ipmi_max_users: 2)
      end
      let(:params) do
        {
          'users' => [
            { 'username' => 'other', 'password' => 'secret' },
          ],
        }
      end

      it do
        is_expected.to compile.and_raise_error(%r{Max users is 2 and all ids are taken})
      end
    end

    describe 'allocating new id user chooses id within gap in existing users' do
      let :facts do
        super().merge(ipmi_users: [
                                    {
                                      'id'         => 1,
                                      'username'   => '',
                                      'fixed_name' => true,
                                      'enabled'    => false,
                                    },
                                    {
                                      'id'         => 2,
                                      'username'   => 'ADMIN',
                                      'fixed_name' => true,
                                      'enabled'    => true,
                                      'priv'       => 4,
                                    },
                                    {
                                      'id'         => 4,
                                      'username'   => 'other',
                                      'fixed_name' => false,
                                      'enabled'    => true,
                                      'priv'       => 4,
                                    },
                                  ])
      end
      let(:params) do
        {
          'users' => [
            { 'username' => 'newuser', 'password' => 'secret' },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_3').with(username: 'newuser')
      end
    end
  end

  describe 'foreman_user => true' do
    let :facts do
      {
        osfamily:        'Debian',
        ipmi_macaddress: 'ac:1f:6b:7f:d4:ce',
        ipmi_max_users:  10,
        ipmi_users:      [
                           {
                             'id'         => 1,
                             'username'   => '',
                             'fixed_name' => true,
                             'enabled'    => false,
                           },
                           {
                             'id'         => 2,
                             'username'   => 'ADMIN',
                             'fixed_name' => true,
                             'enabled'    => true,
                             'priv'       => 4,
                           },
                         ],
      }
    end
    let :node_params do
      {
        'foreman_interfaces' => [
          {
            'mac'  => 'ac:1f:6b:7f:d5:16',
            'type' => 'Interface',
          },
          {
            'mac'  => 'ac:1f:6b:7f:d5:17',
            'type' => 'Interface',
          },
          {
            'mac'      => 'ac:1f:6b:7f:d4:ce',
            'type'     => 'BMC',
            'username' => 'ADMIN',
            'password' => 'SECRET',
          },
        ],
      }
    end

    describe 'matching existing BMC user' do
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to contain_ipmi__user('id_2').with(id:        2,
                                                       username:  'ADMIN',
                                                       password:  'SECRET',
                                                       privilege: 4,
                                                       channel:   1)
      end
    end

    describe 'specify privilege' do
      let(:params) do
        {
          'foreman_user'           => true,
          'foreman_user_privilege' => 3,
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(privilege: 3)
      end
    end

    describe 'adding new Foreman user' do
      let :facts do
        super().merge(ipmi_users: [
                                    {
                                      'id'         => 1,
                                      'username'   => '',
                                      'fixed_name' => true,
                                      'enabled'    => false,
                                    },
                                    {
                                      'id'         => 2,
                                      'username'   => 'root',
                                      'fixed_name' => true,
                                      'enabled'    => true,
                                      'priv'       => 4,
                                    },
                                  ])
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to contain_ipmi__user('id_3').with(id:        3,
                                                       username:  'ADMIN',
                                                       password:  'SECRET',
                                                       privilege: 4,
                                                       channel:   1)
        is_expected.to have_ipmi__user_resource_count(1)
      end
    end

    describe 'fail when no foreman_interfaces parameter from Foreman ENC' do
      let :node_params do
        {}
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to compile.and_raise_error(%r{Unknown variable: '::foreman_interfaces'})
      end
    end

    describe 'noop when optional and no BMC interface in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'  => 'ac:1f:6b:7f:d5:16',
              'type' => 'Interface',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => 'optional' } }

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'fail when true and no BMC interface in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'  => 'ac:1f:6b:7f:d5:16',
              'type' => 'Interface',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to compile.and_raise_error(%r{No BMC interface})
      end
    end

    describe 'noop when optional and no BMC interface matches macaddress' do
      let :facts do
        super().merge('ipmi_macaddress' => 'totally-different')
      end
      let(:params) { { 'foreman_user' => 'optional' } }

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'fail when true and no BMC interface in Foreman' do
      let :facts do
        super().merge('ipmi_macaddress' => 'totally-different')
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to compile.and_raise_error(%r{No BMC interface})
      end
    end

    describe 'noop when optional and no username on BMC interface in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'      => 'ac:1f:6b:7f:d4:ce',
              'type'     => 'BMC',
              'username' => '',
              'password' => '',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => 'optional' } }

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'fail when true and no username on BMC interface in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'      => 'ac:1f:6b:7f:d4:ce',
              'type'     => 'BMC',
              'username' => '',
              'password' => '',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to compile.and_raise_error(%r{No username on BMC interface})
      end
    end

    describe 'noop when optional and no password set in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'      => 'ac:1f:6b:7f:d4:ce',
              'type'     => 'BMC',
              'username' => 'ADMIN',
              'password' => '',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => 'optional' } }

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'fail when true and no password set in Foreman' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'      => 'ac:1f:6b:7f:d4:ce',
              'type'     => 'BMC',
              'username' => 'ADMIN',
              'password' => '',
            },
          ],
        }
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to compile.and_raise_error(%r{No password on BMC interface})
      end
    end

    describe 'noop when no users fact' do
      let :facts do
        { 'osfamily' => 'Debian' }
      end
      let(:params) { { 'foreman_user' => true } }

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end
  end

  describe 'purge_users => true' do
    let :facts do
      {
        osfamily:        'Debian',
        ipmi_macaddress: 'ac:1f:6b:7f:d4:ce',
        ipmi_max_users:  10,
        ipmi_users:      [
                           {
                             'id'         => 1,
                             'username'   => '',
                             'fixed_name' => true,
                             'enabled'    => false,
                           },
                           {
                             'id'         => 2,
                             'username'   => 'ADMIN',
                             'fixed_name' => true,
                             'enabled'    => true,
                             'priv'       => 4,
                           },
                           {
                             'id'         => 3,
                             'username'   => 'foreman',
                             'fixed_name' => false,
                             'enabled'    => true,
                             'priv'       => 4,
                           },
                           {
                             'id'         => 4,
                             'username'   => 'old',
                             'fixed_name' => false,
                             'enabled'    => false,
                             'priv'       => 4,
                           },
                         ],
      }
    end

    describe 'disables all when none provided' do
      let(:params) do
        { 'purge_users' => true }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(id: 2, ensure: 'absent')
        is_expected.to contain_ipmi__user('id_3').with(id: 3, ensure: 'absent')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'disables extraneous when some provided' do
      let(:params) do
        {
          'purge_users' => true,
          'users'       => [
            {
              'id'       => 3,
              'username' => 'other',
              'password' => 'SSSSHH',
            },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(id: 2, ensure: 'absent')
        is_expected.to contain_ipmi__user('id_3')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'does not purge foreman_user' do
      let :node_params do
        {
          'foreman_interfaces' => [
            {
              'mac'      => 'ac:1f:6b:7f:d4:ce',
              'type'     => 'BMC',
              'username' => 'ADMIN',
              'password' => 'SECRET',
            },
          ],
        }
      end
      let(:params) do
        {
          'purge_users'  => true,
          'foreman_user' => true,
          'users'        => [
            {
              'id'       => 3,
              'username' => 'other',
              'password' => 'SSSSHH',
            },
          ],
        }
      end

      it do
        is_expected.to contain_ipmi__user('id_2').with(username: 'ADMIN')
        is_expected.to contain_ipmi__user('id_3')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'noop when no users fact' do
      let :facts do
        { 'osfamily' => 'Debian' }
      end
      let(:params) do
        { 'purge_users' => true }
      end

      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end
  end

  describe 'snmp' do
    let :facts do
      {
        'osfamily'     => 'Debian',
        'ipmi_channel' => 1,
      }
    end
    let(:params) do
      { 'snmp' => 'public' }
    end

    it do
      is_expected.to contain_ipmi__snmp('init').with(snmp: 'public', channel: 1)
    end
  end

  describe 'network' do
    let :facts do
      {
        'osfamily'     => 'Debian',
        'ipmi_channel' => 1,
      }
    end
    let(:params) do
      {
        'network' => {
          'type' => 'dhcp',
        },
      }
    end

    it do
      is_expected.to contain_ipmi__network('init').with(type: 'dhcp', channel: 1)
    end
  end
end
