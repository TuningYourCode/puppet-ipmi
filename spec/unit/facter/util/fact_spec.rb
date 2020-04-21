require 'spec_helper'

describe Facter::Util::Fact do
  before(:each) do
    Facter.clear
    Facter::Core::Execution.stubs(:execute)
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
        summary_output = <<-EOS
Maximum IDs	        : 10
Enabled User Count  : 2
Fixed Name Count    : 2
        EOS
        anon_user_output = <<-EOS
Maximum User IDs     : 10
Enabled User IDs     : 2

User ID              : 1
User Name            :
Fixed Name           : Yes
Access Available     : call-in / callback
Link Authentication  : disabled
IPMI Messaging       : disabled
Privilege Level      : Unknown (0x00)
Enable Status        : disabled
        EOS
        fixed_user_output = <<-EOS
Maximum User IDs     : 10
Enabled User IDs     : 2

User ID              : 2
User Name            : ADMIN
Fixed Name           : Yes
Access Available     : callback
Link Authentication  : disabled
IPMI Messaging       : enabled
Privilege Level      : ADMINISTRATOR
Enable Status        : enabled
        EOS
        added_user_output = <<-EOS
Maximum User IDs     : 10
Enabled User IDs     : 2

User ID              : 3
User Name            : foreman
Fixed Name           : No
Access Available     : call-in / callback
Link Authentication  : enabled
IPMI Messaging       : enabled
Privilege Level      : USER
Enable Status        : enabled
        EOS
        empty_user_output = <<-EOS
Maximum User IDs     : 10
Enabled User IDs     : 2

User ID              : 4
User Name            :
Fixed Name           : No
Access Available     : call-in / callback
Link Authentication  : disabled
IPMI Messaging       : disabled
Privilege Level      : Unknown (0x00)
Enable Status        : disabled
        EOS
        Facter::Core::Execution.expects(:which).at_least(1).with('ipmitool').returns('/usr/bin/ipmitool')
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool lan print 1 2>&1').returns(ipmitool_output)
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool user summary 2>&1').returns(summary_output)
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool channel getaccess 1 1 2>&1').returns(anon_user_output)
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool channel getaccess 1 2 2>&1').returns(fixed_user_output)
        Facter::Core::Execution.expects(:execute).at_least(1).with('ipmitool channel getaccess 1 3 2>&1').returns(added_user_output)
        (4..10).to_a.each do |mock_user_id|
          Facter::Core::Execution.expects(:execute).at_least(1).with("ipmitool channel getaccess 1 #{mock_user_id} 2>&1").returns(empty_user_output)
        end
        Facter.fact(:kernel).stubs(:value).returns('Linux')
      end
      let(:facts) { {kernel: 'Linux'} }

      it do
        expect(Facter.value(:ipmi_channel)).to eq(1)
        expect(Facter.value(:ipmi_ipaddress)).to eq('192.168.0.37')
        expect(Facter.value(:ipmi_ipaddress_source)).to eq('DHCP Address')
        expect(Facter.value(:ipmi_subnet_mask)).to eq('255.255.255.0')
        expect(Facter.value(:ipmi_macaddress)).to eq('3c:a8:2a:9f:9a:92')
        expect(Facter.value(:ipmi_gateway)).to eq('192.168.0.1')
        # noinspection RubyStringKeysInHashInspection
        expect(Facter.value(:ipmi_users)).to eq([
                                                    {
                                                        'id' => 1,
                                                        'username' => '',
                                                        'fixed_name' => true,
                                                        'enabled' => false,
                                                    },
                                                    {
                                                        'id' => 2,
                                                        'username' => 'ADMIN',
                                                        'fixed_name' => true,
                                                        'enabled' => true,
                                                        'priv' => 4,
                                                    },
                                                    {
                                                        'id' => 3,
                                                        'username' => 'foreman',
                                                        'fixed_name' => false,
                                                        'enabled' => true,
                                                        'priv' => 2,
                                                    },
                                                ])
      end
    end

    context 'returns only channel when ipmitool not present' do
      before(:each) do
        Facter::Core::Execution.expects(:which).at_least(1).with('ipmitool').returns(false)
        Facter.fact(:kernel).stubs(:value).returns('Linux')
      end
      let(:facts) { {kernel: 'Linux'} }

      it do
        expect(Facter.value(:ipmi_channel)).to eq(1)
        expect(Facter.value(:ipmi_ipaddress)).to be_nil
        expect(Facter.value(:ipmi_users)).to be_nil
      end
    end
  end
end
