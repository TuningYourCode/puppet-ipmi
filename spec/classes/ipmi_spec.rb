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
        is_expected.to contain_service('ipmi').with(ensure: 'running',
                                                    enable: true)
        is_expected.to contain_service('ipmievd').with(ensure: 'stopped',
                                                       enable: false)
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
        is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                       enable: true)
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
        is_expected.to contain_service('openipmi').with(ensure: 'running',
                                                        enable: true)
        is_expected.to contain_service('ipmievd').with(ensure: 'stopped',
                                                       enable: false)
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
        is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                       enable: true)
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
          other: {id: 3, priv: 1},
      }} }

      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2,
                                                        password: 'secret')
        is_expected.to contain_ipmi__user('other').with(id: 3,
                                                        priv: 1)
      end
    end
  end

  describe 'foreman_user' do
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
          'foreman_interfaces': [
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
      let(:params) { {foreman_user: true} }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2,
                                                        password: 'SECRET')
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
      let(:params) { {foreman_user: true} }
      it do
        is_expected.to contain_ipmi__user('ADMIN').with(id: 3,
                                                        password: 'SECRET')
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
        is_expected.to contain_ipmi__user('ADMIN').with(id: 2,
                                                        password: 'SECRET')
        is_expected.to contain_ipmi__user('other').with(id: 3,
                                                        password: 'SSSSHH')
      end
    end

    describe 'noop when no BMC interface' do
      let :node_params do
        {
            'foreman_interfaces': [
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
      let(:params) { {foreman_user: true} }
      it do
        is_expected.to have_ipmi__user_resource_count(0)
      end
    end

  end
end
