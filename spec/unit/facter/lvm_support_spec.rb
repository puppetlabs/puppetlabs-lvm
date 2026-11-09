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
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('which').with('vgs').at_least(1).returns(nil)
        Facter.value(:lvm_support).should be_nil
      end
    end

    context 'when vgs is present' do
      it 'is set to yes' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('which').with('vgs').returns('/sbin/vgs')
        Facter.value(:lvm_support).should be_truthy
      end
    end
  end
end
