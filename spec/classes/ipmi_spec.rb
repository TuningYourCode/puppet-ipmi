require 'spec_helper'

describe 'ipmi', type: :class do
  describe 'for osfamily RedHat' do
    let :facts do
      {
          osfamily: 'RedHat',
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

    describe 'ensure => stopped' do
      let(:params) { {ensure: 'absent'} }

      it do
        is_expected.to contain_package('OpenIPMI').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { {ipmievd_service_ensure: 'running'} }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running', enable: true)
      end
    end

    describe 'watchdog => true' do
      let(:params) { {watchdog: true} }

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
      let(:params) { {ensure: 'absent'} }

      it do
        is_expected.to contain_package('openipmi').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { {ipmievd_service_ensure: 'running'} }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running', enable: true)
      end
    end

    describe 'watchdog => true' do
      let(:params) { {watchdog: true} }

      it do
        is_expected.to contain_augeas('/etc/default/openipmi').with(context: '/files/etc/default/openipmi',
                                                                    changes: 'set IPMI_WATCHDOG yes')
      end
    end
  end

  describe 'users' do
    let :facts do
      {
          osfamily: 'Debian',
      }
    end

    describe 'users => {...}' do
      let(:params) { {users: {
          ADMIN: {id: 2, password: 'secret'},
          other: {id: 3, privilege: 1},
      }} }

      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: 'secret')
        is_expected.to contain_ipmi__user('other').with(id: 3, privilege: 1)
      end
    end
  end

  describe 'foreman_user => true' do
    let :facts do
      {
          osfamily: 'Debian',
          ipmi_users: [
              {
                  'id' => 1,
                  'username' => '',
                  'fixed_name' => true,
                  'enabled' => false
              },
              {
                  'id' => 2,
                  'username' => 'ADMIN',
                  'fixed_name' => true,
                  'enabled' => true,
                  'priv' => 4
              },
          ],
      }
    end
    let :node_params do
      {
          'foreman_interfaces' => [
              {
                  'ip' => '10.100.1.40',
                  'mac' => 'ac:1f:6b:7f:d5:16',
                  'type' => 'Interface'
              },
              {
                  'mac' => 'ac:1f:6b:7f:d5:17',
                  'type' => 'Interface'
              },
              {
                  'ip' => '10.100.1.138',
                  'mac' => 'ac:1f:6b:7f:d4:ce',
                  'type' => 'BMC',
                  'provider' => 'IPMI',
                  'username' => 'ADMIN',
                  'password' => 'SECRET'
              }
          ]
      }
    end

    describe 'matching existing BMC user' do
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: 'SECRET', privilege: 4)
      end
    end

    describe 'specify privilege' do
      let(:params) do
        {
            'foreman_user' => true,
            'foreman_user_privilege' => 3,
        }
      end
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: 'SECRET', privilege: 3)
      end
    end

    describe 'adding new BMC user' do
      let :facts do
        {
            osfamily: 'Debian',
            ipmi_users: [
                {
                    'id' => 1,
                    'username' => '',
                    'fixed_name' => true,
                    'enabled' => false
                },
                {
                    'id' => 2,
                    'username' => 'root',
                    'fixed_name' => true,
                    'enabled' => true,
                    'priv' => 4
                },
            ],
        }
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 3, password: 'SECRET', privilege: 4)
        is_expected.to have_ipmi__user_resource_count(1)
      end
    end

    describe 'add to passed users' do
      let(:params) { {
          'foreman_user' => true,
          'users' => {
              'other' => {
                  'id' => 3,
                  'password' => 'SSSSHH',
              }
          },
      } }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: 'SECRET', privilege: 4)
        is_expected.to contain_ipmi__user('other').with(id: 3, password: 'SSSSHH')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'leave password as is if no password set in Foreman' do
      let :node_params do
        {
            'foreman_interfaces' => [
                {
                    'ip' => '10.100.1.40',
                    'mac' => 'ac:1f:6b:7f:d5:16',
                    'type' => 'Interface'
                },
                {
                    'mac' => 'ac:1f:6b:7f:d5:17',
                    'type' => 'Interface'
                },
                {
                    'ip' => '10.100.1.138',
                    'mac' => 'ac:1f:6b:7f:d4:ce',
                    'type' => 'BMC',
                    'provider' => 'IPMI',
                    'username' => 'ADMIN',
                    'password' => ''
                }
            ]
        }
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: nil, privilege: 4)
      end
    end

    describe 'fail when no foreman_interfaces parameter from Foreman ENC' do
      let :node_params do
        {}
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to compile.and_raise_error(/Unknown variable: '::foreman_interfaces'/)
      end
    end

    describe 'noop when no BMC interface in Foreman' do
      let :node_params do
        {
            'foreman_interfaces' => [
                {
                    'ip' => '10.100.1.40',
                    'mac' => 'ac:1f:6b:7f:d5:16',
                    'type' => 'Interface'
                },
                {
                    'mac' => 'ac:1f:6b:7f:d5:17',
                    'type' => 'Interface'
                },
            ]
        }
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'noop when no username on BMC interface in Foreman' do
      let :node_params do
        {
            'foreman_interfaces' => [
                {
                    'ip' => '10.100.1.40',
                    'mac' => 'ac:1f:6b:7f:d5:16',
                    'type' => 'Interface'
                },
                {
                    'mac' => 'ac:1f:6b:7f:d5:17',
                    'type' => 'Interface'
                },
                {
                    'ip' => '10.100.1.138',
                    'mac' => 'ac:1f:6b:7f:d4:ce',
                    'type' => 'BMC',
                    'provider' => 'IPMI',
                    'username' => '',
                    'password' => ''
                }
            ]
        }
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

    describe 'noop when no users fact' do
      let :facts do
        {'osfamily' => 'Debian'}
      end
      let(:params) { {'foreman_user' => true} }
      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end
  end

  describe 'purge_users => true' do
    let :facts do
      {
          osfamily: 'Debian',
          ipmi_users: [
              {
                  'id' => 1,
                  'username' => '',
                  'fixed_name' => true,
                  'enabled' => false
              },
              {
                  'id' => 2,
                  'username' => 'ADMIN',
                  'fixed_name' => true,
                  'enabled' => true,
                  'priv' => 4
              },
              {
                  'id' => 3,
                  'username' => 'foreman',
                  'fixed_name' => false,
                  'enabled' => true,
                  'priv' => 4
              },
              {
                  'id' => 4,
                  'username' => 'old',
                  'fixed_name' => false,
                  'enabled' => false,
                  'priv' => 4
              },
          ],
      }
    end

    describe 'disables all when none provided' do
      let(:params) do
        {'purge_users' => true}
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
            'users' => {
                'other' => {
                    'id' => 3,
                    'password' => 'SSSSHH',
                }
            },
        }
      end
      it do
        is_expected.to contain_ipmi__user('id_2').with(id: 2, ensure: 'absent')
        is_expected.to contain_ipmi__user('other').with(id: 3, password: 'SSSSHH')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'does not purge foreman_user' do
      let :node_params do
        {
            'foreman_interfaces' => [
                {
                    'ip' => '10.100.1.40',
                    'mac' => 'ac:1f:6b:7f:d5:16',
                    'type' => 'Interface'
                },
                {
                    'mac' => 'ac:1f:6b:7f:d5:17',
                    'type' => 'Interface'
                },
                {
                    'ip' => '10.100.1.138',
                    'mac' => 'ac:1f:6b:7f:d4:ce',
                    'type' => 'BMC',
                    'provider' => 'IPMI',
                    'username' => 'ADMIN',
                    'password' => 'SECRET'
                }
            ]
        }
      end
      let(:params) do
        {
            'purge_users' => true,
            'foreman_user' => true,
            'users' => {
                'other' => {
                    'id' => 3,
                    'password' => 'SSSSHH',
                }
            },
        }
      end
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2, password: 'SECRET', privilege: 4)
        is_expected.to contain_ipmi__user('other').with(id: 3, password: 'SSSSHH')
        is_expected.to have_ipmi__user_resource_count(2)
      end
    end

    describe 'noop when no users fact' do
      let :facts do
        {'osfamily' => 'Debian' }
      end
      let(:params) do
        {'purge_users' => true}
      end
      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end
  end
end
