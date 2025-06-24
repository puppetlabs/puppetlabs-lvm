# frozen_string_literal: true

require 'spec_helper'

describe 'lvm::volume' do
  let(:title) { 'lv_example0' }

  let :params do
    {
      ensure: 'present',
      vg: 'vg_example0',
      fstype: 'ext4',
      size: '100GB'
    }
  end

  context 'when passed with a single pv, it will compile' do
    let(:params) do
      super().merge({ 'pv' => '/dev/sdd1' })
    end

    it {
      expect(subject).to compile
    }
  end

  context 'when passed with multiple pvs, it will compile' do
    let(:params) do
      super().merge({ 'pv' => ['/dev/sdd1', '/dev/sde2'] })
    end

    it {
      expect(subject).to compile
    }
  end
end
