require 'spec_helper'

describe 'ipmi::user', type: :define do
  let(:facts) do
    {
      operatingsystem: 'Ubuntu',
      osfamily: 'debian',
      operatingsystemmajrelease: '18.04',
      ipmi_channel: 1,
    }
  end

  let(:title) { 'newuser' }

  describe 'when deploying with minimum params' do
    let(:params) do
      {
        id: 3,
      }
    end

    it { is_expected.to contain_exec('ipmi_user_add_newuser').that_comes_before('Exec[ipmi_user_priv_newuser]') }
    it { is_expected.to contain_exec('ipmi_user_add_newuser').that_comes_before('Exec[ipmi_user_enable_newuser]') }

    it { is_expected.to contain_exec('ipmi_user_enable_newuser') }

    it { is_expected.to contain_exec('ipmi_user_priv_newuser').that_notifies('Exec[ipmi_user_enable_sol_newuser]') }

    it { is_expected.to contain_exec('ipmi_user_enable_sol_newuser').with('refreshonly' => 'true') }
  end

  describe 'when deploying with all params' do
    let(:params) do
      {
        username: 'newuser1',
        password: 'password',
        privilege: 3,
        id: 4,
      }
    end

    it { is_expected.to contain_exec('ipmi_user_add_newuser').that_comes_before('Exec[ipmi_user_priv_newuser]') }
    it { is_expected.to contain_exec('ipmi_user_add_newuser').that_comes_before('Exec[ipmi_user_setpw_newuser]') }
    it { is_expected.to contain_exec('ipmi_user_add_newuser').that_comes_before('Exec[ipmi_user_enable_newuser]') }

    it { is_expected.to contain_exec('ipmi_user_enable_newuser') }

    it { is_expected.to contain_exec('ipmi_user_priv_newuser').that_notifies('Exec[ipmi_user_enable_sol_newuser]') }

    it { is_expected.to contain_exec('ipmi_user_setpw_newuser').that_notifies('Exec[ipmi_user_enable_sol_newuser]') }

    it { is_expected.to contain_exec('ipmi_user_enable_sol_newuser').with('refreshonly' => 'true') }
  end

  describe 'when deploying absent' do
    let(:params) do
      {
        ensure: 'absent',
        id: 3,
      }
    end

    it { is_expected.to contain_exec('ipmi_user_disable_newuser') }
  end

  describe 'when deploying with invalid privilege' do
    let(:params) do
      {
        user: 'newuser1',
        password: 'password',
        privilege: 5,
        id: 4,
      }
    end

    it 'fails and raise invalid privilege error' do
      expect { is_expected.to contain_exec('ipmi_user_enable_newuser') }.to raise_error(Puppet::PreformattedError, %r{'privilege' expects an Integer\[1, 4\]})
    end
  end
end
