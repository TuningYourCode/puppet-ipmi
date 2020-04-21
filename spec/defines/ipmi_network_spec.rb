require 'spec_helper'

describe 'ipmi::network', type: :define do
  let(:facts) do
    {
      operatingsystem: 'Ubuntu',
      osfamily: 'debian',
      operatingsystemmajrelease: '18.04',
      ipmi_channel: 1,
    }
  end

  let(:title) { 'example' }

  describe 'when deploying as dhcp with minimal params' do
    let(:params) do
      {
        type: 'dhcp',
      }
    end

    it { is_expected.to contain_exec('ipmi_set_dhcp_1') }
  end

  describe 'when deploying as dhcp with all params' do
    let(:params) do
      {
        ip: '1.1.1.1',
        netmask: '255.255.255.0',
        gateway: '2.2.2.2',
        type: 'dhcp',
      }
    end

    it { is_expected.to contain_exec('ipmi_set_dhcp_1') }
  end

  describe 'when deploying as static with minimal params' do
    let(:params) do
      {
        ip: '1.1.1.10',
        netmask: '255.255.255.0',
        gateway: '1.1.1.1',
        type: 'static',
      }
    end

    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_ipaddr_1]') }
    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_defgw_1]') }
    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_netmask_1]') }
  end

  describe 'when deploying as static with all params' do
    let(:params) do
      {
        ip: '1.1.1.10',
        netmask: '255.255.255.0',
        gateway: '1.1.1.1',
        type: 'static',
      }
    end

    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_ipaddr_1]') }
    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_defgw_1]') }
    it { is_expected.to contain_exec('ipmi_set_static_1').that_notifies('Exec[ipmi_set_netmask_1]') }
  end
end
