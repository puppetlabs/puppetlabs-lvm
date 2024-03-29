# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:logical_volume).provider(:lvm)

describe provider_class do
  before(:each) do
    @resource = stub_everything('resource')
    @provider = provider_class.new(@resource)
  end

  lvs_output = <<-OUTPUT
  LV      VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup   -wi-ao----  18.54g
  lv_swap VolGroup   -wi-ao---- 992.00m
  data    data       -wi-ao---- 992.00m
  j1      vg_jenkins -wi-a-----   1.00g
  OUTPUT

  describe 'self.instances' do
    before :each do
      @provider.class.stubs(:lvs).returns(lvs_output)
    end

    it 'returns an array of logical volumes' do
      logical_volumes = @provider.class.instances.map(&:name)

      expect(logical_volumes).to include('lv_root', 'lv_swap')
    end
  end

  describe 'when checking existence' do
    it "returns 'true', lv 'data' in vg 'data' exists" do
      @resource.expects(:[]).with(:name).returns('data')
      @resource.expects(:[]).with(:volume_group).returns('data').at_least_once
      @provider.class.stubs(:lvs).with('data').returns(lvs_output)
      expect(@provider.exists?).to be > 10
    end

    it "returns 'nil', lv 'jenkins' in vg 'vg_jenkins' exists" do
      @resource.expects(:[]).with(:name).returns('jenkins')
      @resource.expects(:[]).with(:volume_group).returns('vg_jenkins').at_least_once
      @provider.class.stubs(:lvs).with('vg_jenkins').returns(lvs_output)
      expect(@provider.exists?).to be_nil
    end

    it "returns 'nil', lv 'swap' in vg 'VolGroup' exists" do
      @resource.expects(:[]).with(:name).returns('swap')
      @resource.expects(:[]).with(:volume_group).returns('VolGroup').at_least_once
      @provider.class.stubs(:lvs).with('VolGroup').returns(lvs_output)
      expect(@provider.exists?).to be_nil
    end

    it "returns 'nil', lv 'data' in vg 'myvg' does not exist" do
      @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
      @provider.class.stubs(:lvs).with('myvg').raises(Puppet::ExecutionFailure, 'Execution of \'/sbin/lvs myvg\' returned 5')
      expect(@provider.exists?).to be_nil
    end
  end

  describe 'when inspecting' do
    it 'strips zeros from lvs output' do
      @resource.expects(:[]).with(:name).returns('mylv').at_least_once
      @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
      @resource.expects(:[]).with(:size).returns('2.5g').at_least_once
      @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 2.50g').at_least_once
      expect(@provider.size).to eq('2.5G')
    end
  end

  describe 'when creating' do
    context 'with size' do
      it "executes 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end

    context 'with size and type' do
      it "executes 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:type).returns('linear').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--type', 'linear', 'myvg')
        @provider.create
      end
    end

    context 'with initial_size' do
      it "executes 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:initial_size).returns('1g').at_least_once
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end

    context 'without size and without extents' do
      it "executes 'lvcreate' without a '--size' option or a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @resource.expects(:[]).with(:initial_size).returns(nil).at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--extents', '100%FREE', 'myvg')
        @provider.create
      end
    end

    context 'with extents' do
      it "executes 'lvcreate' with a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:extents).returns('80%vg').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--extents', '80%vg', 'myvg')
        @provider.create
      end
    end

    context 'without extents' do
      it "executes 'lvcreate' without a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end

    context 'with initial_size and mirroring' do
      it "executes 'lvcreate' with '--size' and '--mirrors' and '--mirrorlog' options" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:initial_size).returns('1g').at_least_once
        @resource.expects(:[]).with(:mirror).returns('1').at_least_once
        @resource.expects(:[]).with(:mirrorlog).returns('core').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--mirrors', '1', '--mirrorlog', 'core', 'myvg')
        @provider.create
      end
    end

    context 'with persistent minor block device' do
      it "executes 'lvcreate' with '--persistent y' and '--minor 100' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:persistent).returns(:true).at_least_once
        @resource.expects(:[]).with(:minor).returns('100').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--persistent', 'y', '--minor', '100', 'myvg')
        @provider.create
      end
    end

    context 'with named thinpool option' do
      it "executes 'lvcreate' with '--virtualsize 1g' and '--thin myvg/mythinpool' options" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:thinpool).returns('mythinpool').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--virtualsize', '1g', '--thin', 'myvg/mythinpool')
        @provider.create
      end
    end
  end

  describe 'when modifying' do
    context 'with a larger size' do
      context 'in extent portions' do
        it "executes 'lvextend'" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
          @provider.expects(:blkid).with('/dev/myvg/mylv')
          @provider.size = '2000000k'
        end

        context 'with resize_fs flag' do
          it "executes 'blkid' if resize_fs is set to true" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @resource.expects(:[]).with(:resize_fs).returns('true').at_least_once
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
            @provider.expects(:blkid).with('/dev/myvg/mylv')
            @provider.size = '2000000k'
          end

          it "does not execute 'blkid' if resize_fs is set to false" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @resource.expects(:[]).with(:resize_fs).returns('false').at_least_once
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
            @provider.expects(:blkid).with('/dev/myvg/mylv').never
            @provider.size = '2000000k'
          end

          it "does not report an error from 'blkid' if resizing a filesystem with no filesystem present" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            expect { @provider.size = '1100000k' }.not_to raise_error(Puppet::ExecutionFailure, %r{blkid})
          end
        end

        context 'with defined thin pool' do
          it "executes 'lvextend' as with normal volume" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @resource.expects(:[]).with(:thinpool).returns('mythinpool').at_least_once
            @provider.expects(:blkid).with('/dev/myvg/mylv').returns('TYPE=ext4')
            @provider.expects(:lvcreate).with('-n', 'mylv', '--virtualsize', '1g', '--thin', 'myvg/mythinpool')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
            @provider.size = '2000000k'
          end
        end
      end

      context 'not in extent portions' do
        it 'raises an exception' do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1.15g' }.should raise_error(Puppet::Error)
        end
      end
    end

    context 'with a smaller size' do
      context 'without size_is_minsize set to false' do
        it 'raises an exception' do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:false).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should raise_error(Puppet::Error, %r{manual})
        end
      end

      context 'with size_is_minsize set to true' do
        it 'does not raise an exception and print info message' do
          Puppet::Util::Log.level = :info
          Puppet::Util::Log.newdestination(:console)
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:true).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should output(%r{already}).to_stdout
        end
      end
    end
  end

  describe 'when destroying' do
    it "executes 'dmsetup' and 'lvremove'" do
      @resource.expects(:[]).with(:volume_group).returns('myvg').times(3)
      @resource.expects(:[]).with(:name).returns('mylv').times(3)
      @provider.expects(:blkid).with('/dev/myvg/mylv')
      @provider.expects(:dmsetup).with('remove', 'myvg-mylv')
      @provider.expects(:lvremove).with('-f', '/dev/myvg/mylv')
      @provider.destroy
    end

    it "executes 'dmsetup' and 'lvremove' and properly escape names with dashes" do
      @resource.expects(:[]).with(:volume_group).returns('my-vg').times(3)
      @resource.expects(:[]).with(:name).returns('my-lv').times(3)
      @provider.expects(:blkid).with('/dev/my-vg/my-lv')
      @provider.expects(:dmsetup).with('remove', 'my--vg-my--lv')
      @provider.expects(:lvremove).with('-f', '/dev/my-vg/my-lv')
      @provider.destroy
    end

    it "executes 'swapoff', 'dmsetup', and 'lvremove' when lvm is of type swap" do
      @resource.expects(:[]).with(:volume_group).returns('myvg').times(4)
      @resource.expects(:[]).with(:name).returns('mylv').times(4)
      @provider.expects(:blkid).with('/dev/myvg/mylv').returns('TYPE="swap"')
      @provider.expects(:swapoff).with('/dev/myvg/mylv')
      @provider.expects(:dmsetup).with('remove', 'myvg-mylv')
      @provider.expects(:lvremove).with('-f', '/dev/myvg/mylv')
      @provider.destroy
    end
  end
end
