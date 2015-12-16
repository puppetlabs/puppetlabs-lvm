# frozen_string_literal: true

require 'spec_helper'

# Generic LVM support
describe 'lvm_support fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'is set to not' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:lvm_support).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when vgs is absent' do
      it 'is set to no' do
        Facter::Core::Execution.expects('which').with('vgs').at_least(1).returns(nil)
        Facter.value(:lvm_support).should be_nil
      end
    end

    context 'when vgs is present' do
      it 'is set to yes' do
        Facter::Core::Execution.expects('which').with('vgs').returns('/sbin/vgs')
        Facter.value(:lvm_support).should be_truthy
      end
    end
  end
end

# VGs
describe 'lvm_vgs facts' do
  before :each do
    Facter.clear
  end

  context 'when there is no lvm support' do
    it 'does not exist' do
      Facter.fact(:lvm_support).expects(:value).at_least(1).returns(nil)
      Facter.value(:lvm_vgs).should be_nil
    end
  end

  context 'when there is lvm support' do
    context 'when there are no vgs' do
      it 'is set to 0' do
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter::Core::Execution.stubs(:execute) # All other calls
        Facter::Core::Execution.expects(:execute).at_least(0).with('vgs -o name --noheadings 2>/dev/null', timeout: 30).returns(nil)
        Facter.value(:lvm_vgs).should == 0
      end
    end

    context 'when there are vgs' do
      before :each do
        Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
        Facter::Util::Resolution.expects('which').with('vgs').at_least(1).returns('/sbin/vgs')
        Facter::Core::Execution.stubs(:execute) # All other calls
      end

      it 'lists vgs' do
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o name --noheadings 2>/dev/null', timeout: 30).returns("vg0\nvg1")
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o pv_name vg0 2>/dev/null', timeout: 30).returns("  PV\n  /dev/pv3\n  /dev/pv2")
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o pv_name vg1 2>/dev/null', timeout: 30).returns("  PV\n  /dev/pv0")
        expect(Facter.value(:lvm_vgs)).to eq(2)
        expect(Facter.value(:lvm_vg_0)).to eq('vg0')
        expect(Facter.value(:lvm_vg_1)).to eq('vg1')
        expect(Facter.value(:lvm_vg_vg0_pvs)).to eq('/dev/pv2,/dev/pv3')
        expect(Facter.value(:lvm_vg_vg1_pvs)).to eq('/dev/pv0')
      end

      it 'sanitizes vg names' do
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o name --noheadings 2>/dev/null', timeout: 30).returns("vg0\nvg-1")
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o pv_name vg0 2>/dev/null', timeout: 30).returns("  PV\n  /dev/pv3\n  /dev/pv2")
        Facter::Core::Execution.expects(:execute).at_least(1).with('vgs -o pv_name vg-1 2>/dev/null', timeout: 30).returns("  PV\n  /dev/pv0")
        expect(Facter.value(:lvm_vgs)).to eq(2)
        expect(Facter.value(:lvm_vg_0)).to eq('vg0')
        expect(Facter.value(:lvm_vg_1)).to eq('vg-1')
        expect(Facter.value(:lvm_vg_vg0_pvs)).to eq('/dev/pv2,/dev/pv3')
        expect(Facter.value(:lvm_vg_vg_1_pvs)).to eq('/dev/pv0')
      end
    end
  end
end

# PVs
describe 'lvm_pvs facts' do
  before :each do
    Facter.clear
  end

  context 'when there is no lvm support' do
    it 'does not exist' do
      Facter.fact(:lvm_support).expects(:value).at_least(1).returns(nil)
      Facter.value(:lvm_pvs).should be_nil
    end
  end

  context 'when there is lvm support' do
    context 'when there are no pvs' do
      it 'is set to 0' do
        Facter::Core::Execution.stubs('execute') # All other calls
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter::Core::Execution.expects('execute').at_least(0).with('pvs -o name --noheadings 2>/dev/null', timeout: 30).returns(nil)
        Facter.value(:lvm_pvs).should == 0
      end
    end
  end
end
