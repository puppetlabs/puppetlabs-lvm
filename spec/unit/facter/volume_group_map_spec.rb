# frozen_string_literal: true

require 'spec_helper'

describe 'volume_group_map fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to nil' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      expect(Facter.value(:volume_group_map)).to be_nil
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
        expect(Facter.value(:volume_group_map)).to be_nil
      end
    end

    context 'when vgs is present' do
      before :each do
        Facter::Core::Execution.stubs('exec') # All other calls
        Facter::Core::Execution.expects('which').with('vgs').at_least(1).returns('/sbin/vgs')
      end

      it 'is able to resolve vgs and map pvs' do
        Facter.fact(:volume_groups).expects(:value).returns(
          {
            'centos' => {
              'uuid' => 'ZcFkEG-217a-nnc6-PvWx-oXou-7THt-XR6eci',
              'attr' => 'wz--n-', 'permissions' => 'writeable',
              'allocation_policy' => 'normal',
              'size' => '19.51g',
              'free' => '44.00m'
            },
            'tasks' => {
              'uuid' => 'tMqdQC-ukEx-bEft-bLk8-WoM1-jX0a-0p1rri',
              'attr' => 'wz--n-',
              'permissions' => 'writeable',
              'allocation_policy' => 'normal',
              'size' => '3.99g',
              'free' => '2.82g'
            }
          },
        )
        vgs_centos_output = <<-OUTPUT
          /dev/sda
        OUTPUT
        vgs_centos_output.dup.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).with('vgs -o pv_name centos --noheading --nosuffix').returns(vgs_centos_output)
        vgs_tasks_output = <<-OUTPUT
          /dev/sdc
          /dev/sdd2
        OUTPUT
        vgs_tasks_output.dup.lstrip!
        Facter::Core::Execution.expects(:exec).at_least(1).with('vgs -o pv_name tasks --noheading --nosuffix').returns(vgs_tasks_output)

        expect(Facter.value(:volume_group_map)).to include(
          'centos' => '/dev/sda',
          'tasks' => '/dev/sdc,/dev/sdd2',
        )
      end
    end
  end
end
