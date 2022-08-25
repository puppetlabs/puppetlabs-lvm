require 'spec_helper'

describe 'volume_groups fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      expect(Facter.value(:volume_groups)).to be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when vgs is absent' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('vgs').at_least(1).returns(nil)
      end

      it 'is set to nil' do
        expect(Facter.value(:volume_groups)).to be_nil
      end
    end

    context 'when vgs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('vgs').returns('/sbin/vgs')
      end

      it 'is able to resolve vgs' do
        vgs_output = <<-OUTPUT
          ZcFkEG-217a-nnc6-PvWx-oXou-7THt-XR6eci centos wz--n- writeable  normal     953864,00 126472,00 4,00 238466 31618
          tMqdQC-ukEx-bEft-bLk8-WoM1-jX0a-0p1rri tasks  wz--n- writeable  normal      55540,00   6388,00 4,00  13885  1597
        OUTPUT
        vgs_output.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).returns(vgs_output)
        expect(Facter.value(:volume_groups)).to include(
          'centos' => {
            'uuid'              => 'ZcFkEG-217a-nnc6-PvWx-oXou-7THt-XR6eci',
            'attr'              => 'wz--n-', 'permissions' => 'writeable',
            'allocation_policy' => 'normal',
            'size'              => '953864,00',
            'free'              => '126472,00',
            'extent_size'       => '4,00',
            'extent_count'      => '238466',
            'free_count'        => '31618'
          },
          'tasks'  => {
            'uuid' => 'tMqdQC-ukEx-bEft-bLk8-WoM1-jX0a-0p1rri',
            'attr'              => 'wz--n-',
            'permissions'       => 'writeable',
            'allocation_policy' => 'normal',
            'size'              => '55540,00',
            'free'              => '6388,00',
            'extent_size'       => '4,00',
            'extent_count'      => '13885',
            'free_count'        => '1597',
          },
        )
      end
    end
  end
end
