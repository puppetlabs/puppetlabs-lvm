require 'spec_helper'

describe 'logical_volumes fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:logical_volumes).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when lvs is absent' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('lvs').at_least(1).returns(nil)
      end

      it 'is set to nil' do
        Facter.value(:logical_volumes).should be_nil
      end
    end

    context 'when lvs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('lvs').returns('/sbin/lvs')
      end

      it 'is able to resolve VGs' do
        lvs_output = <<-OUTPUT
        {
            "report": [
                {
                    "lv": [
                      {"lv_uuid":"E7qan8-4NGf-jq2P-l11v-6fFe-MPHK-T6IGzl", "lv_name":"root", "lv_full_name":"centos/root, "lv_path":"/dev/centos/root", "lv_dm_path":"/dev/mapper/centos-root", "lv_attr":"-wi-ao----", "lv_layout":"linear", "lv_role":"public", "lv_active":"active", "lv_size":"18.46g", "lv_permissions":"writeable"},
                      {"lv_uuid":"buUXDX-GDUh-rN2t-y80n-vtCt-xhhu-XSZ5kA", "lv_name":"swap", "lv_full_name":"centos/swap", "lv_path":"/dev/centos/swap", "lv_dm_path":"/dev/mapper/centos-swap", "lv_attr":"-wi-ao----", "lv_layout":"linear", "lv_role":"public", "lv_active":"active", "lv_size":"1.00g", "lv_permissions":"writeable"},
                      {"lv_uuid":"uedsry-OTVv-wGW4-vaFf-c7IY-oH6Z-ig6IXB", "lv_name":"cool_tasks", "lv_full_name":"tasks/cool_tasks", "lv_path":"/dev/tasks/cool_tasks", "lv_dm_path":"/dev/mapper/tasks-cool_tasks", "lv_attr":"-wi-ao----", "lv_layout":"linear", "lv_role":"public", "lv_active":"active", "lv_size":"800.00m ", "lv_permissions":"writeable"},
                      {"lv_uuid":"gmNS3G-cAhA-vRj0-2Uf0-21yO-QVdy-LNXfBv ", "lv_name":"lame_tasks", "lv_full_name":"tasks/lame_tasks", "lv_path":"/dev/tasks/lame_tasks", "lv_dm_path":"/dev/mapper/tasks-lame_tasks", "lv_attr":"-wi-ao----", "lv_layout":"linear", "lv_role":"public", "lv_active":"active", "lv_size":"400.00m", "lv_permissions":"writeable"}
                    ]
                }
            ]
        }
        OUTPUT
        lvs_output.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).returns(lvs_output)
        Facter.value(:logical_volumes).should include('cool_tasks' => {
                                                        'lv_uuid' => 'uedsry-OTVv-wGW4-vaFf-c7IY-oH6Z-ig6IXB',
                                                        'lv_full_name'   => 'tasks/cool_tasks',
                                                        'lv_path'        => '/dev/tasks/cool_tasks',
                                                        'lv_dm_path'     => '/dev/mapper/tasks-cool_tasks',
                                                        'lv_attr'        => '-wi-a-----',
                                                        'lv_layout'      => 'linear',
                                                        'lv_role'        => 'public',
                                                        'lv_active'      => 'active',
                                                        'lv_size'        => '800.00m',
                                                        'lv_permissions' => 'writeable',
                                                      },
                                                      'lame_tasks' => {
                                                        'lv_uuid'        => 'gmNS3G-cAhA-vRj0-2Uf0-21yO-QVdy-LNXfBv',
                                                        'lv_full_name'   => 'tasks/lame_tasks',
                                                        'lv_path'        => '/dev/tasks/lame_tasks',
                                                        'lv_dm_path'     => '/dev/mapper/tasks-lame_tasks',
                                                        'lv_attr'        => '-wi-a-----',
                                                        'lv_layout'      => 'linear',
                                                        'lv_role'        => 'public',
                                                        'lv_active'      => 'active',
                                                        'lv_size'        => '400.00m',
                                                        'lv_permissions' => 'writeable',
                                                      },
                                                      'root' => {
                                                        'lv_uuid'        => 'E7qan8-4NGf-jq2P-l11v-6fFe-MPHK-T6IGzl',
                                                        'lv_full_name'   => 'centos/root',
                                                        'lv_path'        => '/dev/centos/root',
                                                        'lv_dm_path'     => '/dev/mapper/centos-root',
                                                        'lv_attr'        => '-wi-ao----',
                                                        'lv_layout'      => 'linear',
                                                        'lv_role'        => 'public',
                                                        'lv_active'      => 'active',
                                                        'lv_size'        => '18.46g',
                                                        'lv_permissions' => 'writeable',
                                                      },
                                                      'swap' => {
                                                        'lv_uuid'        => 'buUXDX-GDUh-rN2t-y80n-vtCt-xhhu-XSZ5kA',
                                                        'lv_full_name'   => 'centos/swap',
                                                        'lv_path'        => '/dev/centos/swap',
                                                        'lv_dm_path'     => '/dev/mapper/centos-swap',
                                                        'lv_attr'        => '-wi-ao----',
                                                        'lv_layout'      => 'linear',
                                                        'lv_role'        => 'public',
                                                        'lv_active'      => 'active',
                                                        'lv_size'        => '1.00g',
                                                        'lv_permissions' => 'writeable',
                                                      })
      end
    end
  end
end
