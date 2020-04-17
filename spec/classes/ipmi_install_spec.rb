require 'spec_helper'

describe 'ipmi::install', type: :class do
  let :pre_condition do
    'include ipmi::params'
  end

  describe 'for osfamily RedHat' do
    let :facts do
      {
        osfamily: 'RedHat',
      }
    end

    describe 'el5.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '5' }

      it { is_expected.to create_class('ipmi::install') }
      it { is_expected.to contain_package('OpenIPMI').with_ensure('present') }
      it { is_expected.to contain_package('OpenIPMI-tools').with_ensure('present') }
    end

    describe 'el6.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '6' }

      it { is_expected.to create_class('ipmi::install') }
      it { is_expected.to contain_package('OpenIPMI').with_ensure('present') }
      it { is_expected.to contain_package('ipmitool').with_ensure('present') }
    end

    describe 'el7.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '7' }

      it { is_expected.to create_class('ipmi::install') }
      it { is_expected.to contain_package('OpenIPMI').with_ensure('present') }
      it { is_expected.to contain_package('ipmitool').with_ensure('present') }
    end
  end
end
