#!/usr/bin/env ruby
#
# IPMI facts, in a format compatible with The Foreman
#
# Sending these facts to a Puppet Server equipped with Foreman
# will cause the latter to create the BMC interfaces the next time the
# Puppet agent runs. One then only has to manually add the access
# credentials, and presto, you can run basic IPMI actions (e.g. reboot
# to PXE) from The Foreman's web UI.
#
# === Fact Format (for Foreman compatibility)
#
#     ipmi_ipaddress = 192.168.101.1
#     ipmi_subnet_mask = 255.255.255.0
#     ...
def load_facts
  return unless Facter::Core::Execution.which('ipmitool')
  ipmitool_output = Facter::Core::Execution.execute("ipmitool lan print #{@channel_id} 2>&1")

  ipmitool_output.each_line do |line|
    case line.strip
    when %r{^IP Address\s*:\s+(\S.*)}
      add_ipmi_fact('ipaddress', Regexp.last_match(1))
    when %r{^IP Address Source\s*:\s+(\S.*)}
      add_ipmi_fact('ipaddress_source', Regexp.last_match(1))
    when %r{^Subnet Mask\s*:\s+(\S.*)}
      add_ipmi_fact('subnet_mask', Regexp.last_match(1))
    when %r{^MAC Address\s*:\s+(\S.*)}
      add_ipmi_fact('macaddress', Regexp.last_match(1))
    when %r{^Default Gateway IP\s*:\s+(\S.*)}
      add_ipmi_fact('gateway', Regexp.last_match(1))
    end
  end
end

def add_ipmi_fact(name, value)
  Facter.add("ipmi_#{name}") do
    confine kernel: 'Linux'
    setcode do
      value
    end
  end
end

@channel_id = 1

load_facts
