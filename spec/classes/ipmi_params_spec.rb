require 'spec_helper'

describe 'ipmi::params', type: :class do
  describe 'for osfamily RedHat' do
    let(:facts) { { osfamily: 'RedHat' } }

    describe 'el5.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '5' }

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'el6.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '6' }

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'el7.x' do
      before(:each) { facts[:operatingsystemmajrelease] = '7' }

      it { is_expected.to create_class('ipmi::params') }
    end
  end

  describe 'for osfamily Debian' do
    let(:facts) { { osfamily: 'Debian' } }

    describe 'Debian' do
      before(:each) { facts[:operatingsystem] = 'Debian' }

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'Ubuntu' do
      before(:each) { facts[:operatingsystem] = 'Ubuntu' }

      it { is_expected.to create_class('ipmi::params') }
    end
  end

  describe 'unsupported osfamily' do
    let :facts do
      {
        osfamily: 'Solaris',
        operatingsystem: 'Nexenta',
      }
    end

    it 'fails' do
      expect { is_expected.to contain_class('ipmi::params') }
        .to raise_error(Puppet::Error, %r{not supported on Nexenta})
    end
  end
end
