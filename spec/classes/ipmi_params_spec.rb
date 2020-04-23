require 'spec_helper'

describe 'ipmi::params', type: :class do
  describe 'for osfamily RedHat' do
    let(:facts) do
      { osfamily: 'RedHat' }
    end

    describe 'el5.x' do
      let(:facts) do
        super().merge(operatingsystemmajrelease: '5')
      end

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'el6.x' do
      let(:facts) do
        super().merge(operatingsystemmajrelease: '6')
      end

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'el7.x' do
      let(:facts) do
        super().merge(operatingsystemmajrelease: '7')
      end

      it { is_expected.to create_class('ipmi::params') }
    end
  end

  describe 'for osfamily Debian' do
    let(:facts) { { osfamily: 'Debian' } }

    describe 'Debian' do
      let(:facts) do
        super().merge(operatingsystem: 'Debian')
      end

      it { is_expected.to create_class('ipmi::params') }
    end

    describe 'Ubuntu' do
      let(:facts) do
        super().merge(operatingsystem: 'Ubuntu')
      end

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
