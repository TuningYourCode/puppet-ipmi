require 'spec_helper'

describe Facter::Util::Fact do
  before(:each) do
    Facter.clear
    File.stubs(:executable?) # Stub all other calls
    Facter::Core::Execution.stubs(:execute) # Catch all other calls
  end

  describe 'ipmi' do
    context 'returns details when ipmitool present' do
      before(:each) do
        ipmitool_output = <<-EOS
        Set in Progress         : Set Complete
        Auth Type Support       :
        Auth Type Enable        : Callback :
        : User     :
        : Operator :
        : Admin    :
        : OEM      :
        IP Address Source       : DHCP Address
        IP Address              : 192.168.0.37
        Subnet Mask             : 255.255.255.0
        MAC Address             : 3c:a8:2a:9f:9a:92
        SNMP Community String   :
        BMC ARP Control         : ARP Responses Enabled, Gratuitous ARP Disabled
        Default Gateway IP      : 192.168.0.1
        802.1q VLAN ID          : Disabled
        802.1q VLAN Priority    : 0
        RMCP+ Cipher Suites     : 0,1,2,3
        Cipher Suite Priv Max   : XuuaXXXXXXXXXXX
        :     X=Cipher Suite Unused
        :     c=CALLBACK
        :     u=USER
        :     o=OPERATOR
        :     a=ADMIN
        :     O=OEM
        Bad Password Threshold  : Not Available
        EOS
        Facter::Core::Execution.expects(:which).at_least(1).with('ipmitool').returns('/usr/bin/ipmitool')
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool lan print 1 2>&1').returns(ipmitool_output)
        Facter.fact(:kernel).stubs(:value).returns('Linux')
      end
      let(:facts) { { kernel: 'Linux' } }

      it do
        expect(Facter.value(:ipmi_ipaddress)).to eq('192.168.0.37')
      end
      it do
        expect(Facter.value(:ipmi_ipaddress_source)).to eq('DHCP Address')
      end
      it do
        expect(Facter.value(:ipmi_subnet_mask)).to eq('255.255.255.0')
      end
      it do
        expect(Facter.value(:ipmi_macaddress)).to eq('3c:a8:2a:9f:9a:92')
      end
      it do
        expect(Facter.value(:ipmi_gateway)).to eq('192.168.0.1')
      end
    end

    context 'returns nil when ipmitool not present' do
      before(:each) do
        Facter.fact(:kernel).stubs(:value).returns('Linux')
      end
      it do
        Facter::Core::Execution.expects(:which).at_least(1).with('ipmitool').returns(false)
        expect(Facter.value(:ipmi_ipaddress)).to be_nil
      end
    end
  end
end
