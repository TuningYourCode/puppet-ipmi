require 'spec_helper'

describe 'ipmi::service::ipmievd', type: :class do
  describe 'no params' do
    it { is_expected.to create_class('ipmi::service::ipmievd') }
    it do
      is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                     hasstatus: true,
                                                     hasrestart: true,
                                                     enable: true)
    end
  end

  describe 'with enable => false' do
    let(:params) { { enable: false } }

    it { is_expected.to create_class('ipmi::service::ipmievd') }
    it do
      is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                     hasstatus: true,
                                                     hasrestart: true,
                                                     enable: false)
    end
  end

  describe 'with enable => true' do
    let(:params) { { enable: true } }

    it { is_expected.to create_class('ipmi::service::ipmievd') }
    it do
      is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                     hasstatus: true,
                                                     hasrestart: true,
                                                     enable: true)
    end
  end

  describe 'with enable => not-a-bool' do
    let(:params) { { enable: 'not-a-bool' } }

    it 'fails' do
      expect {
        is_expected.to create_class('ipmi::service')
      }.to raise_error(Puppet::Error, %r{is not a boolean})
    end
  end

  describe 'with ensure => running' do
    let(:params) { { ensure: 'running' } }

    it { is_expected.to create_class('ipmi::service::ipmievd') }
    it do
      is_expected.to contain_service('ipmievd').with(ensure: 'running',
                                                     hasstatus: true,
                                                     hasrestart: true,
                                                     enable: true)
    end
  end

  describe 'with ensure => running' do
    let(:params) { { ensure: 'stopped' } }

    it { is_expected.to create_class('ipmi::service::ipmievd') }
    it do
      is_expected.to contain_service('ipmievd').with(ensure: 'stopped',
                                                     hasstatus: true,
                                                     hasrestart: true,
                                                     enable: true)
    end
  end

  describe 'with ensure => invalid-string' do
    let(:params) { { ensure: 'invalid-string' } }

    it 'fails' do
      expect {
        is_expected.to create_class('ipmi::service::ipmievd')
      }.to raise_error(Puppet::Error, %r{does not match})
    end
  end
end
