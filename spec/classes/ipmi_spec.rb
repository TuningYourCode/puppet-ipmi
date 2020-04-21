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
      it { is_expected.to create_class('ipmi') }
      it do
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
      let(:params) { { ensure: 'absent' } }

      it do
        is_expected.to contain_package('OpenIPMI').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { { ipmievd_service_ensure: 'running' } }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                       enable: true)
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
        operatingsystem: 'Ubuntu',
      }
    end

    describe 'no params' do
      it { is_expected.to create_class('ipmi') }
      it do
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
      let(:params) { { ensure: 'absent' } }

      it do
        is_expected.to contain_package('openipmi').with_ensure('absent')
        is_expected.to contain_package('ipmitool').with_ensure('absent')
      end
    end

    describe 'ipmievd_service_ensure => running' do
      let(:params) { { ipmievd_service_ensure: 'running' } }

      it do
        is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                       enable: true)
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
end
