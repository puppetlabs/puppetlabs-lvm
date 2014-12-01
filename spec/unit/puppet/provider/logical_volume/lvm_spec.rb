require 'spec_helper'

provider_class = Puppet::Type.type(:logical_volume).provider(:lvm)

describe provider_class do

  before do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
  end

  describe 'when creating' do
    context 'with size' do
      it "should execute 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
    context 'with initial_size' do
      it "should execute 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:initial_size).returns('1g').at_least_once
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
     context 'without size and without extents' do
      it "should execute 'lvcreate' without a '--size' option or a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @resource.expects(:[]).with(:initial_size).returns(nil).at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--extents', '100%FREE', 'myvg')
        @provider.create
      end
    end
    context 'with extents' do
      it "should execute 'lvcreate' with a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:extents).returns('80%vg').at_least_once
        @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--extents', '80%vg', 'myvg')
        @provider.create
      end
    end
    context 'without extents' do
      it "should execute 'lvcreate' without a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
        @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
  end

  describe "when modifying" do
    context "with a larger size" do
      context "in extent portions" do
        it "should execute 'lvextend'" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
          @provider.expects(:blkid).with('/dev/myvg/mylv')
          @provider.size = '2000000k'
        end
      end
      context "not in extent portions" do
        it "should raise an exception" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1.15g' }.should raise_error(Puppet::Error, /extent/)
        end
      end
    end
    context "with a smaller size" do
      context "without size_is_minsize set to false" do
        it "should raise an exception" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:false).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should raise_error(Puppet::Error, /manual/)
        end
      end
      context "with size_is_minsize set to true" do
        it "should not raise an exception and print info message" do 
          Puppet::Util::Log.level = :info
          Puppet::Util::Log.newdestination(:console)
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripes).returns(nil).at_least_once
          @resource.expects(:[]).with(:stripesize).returns(nil).at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:true).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should output(/already/).to_stdout
        end
      end
    end
  end

  describe 'when destroying' do
    it "should execute 'dmsetup' and 'lvremove'" do
      @resource.expects(:[]).with(:volume_group).returns('myvg').twice
      @resource.expects(:[]).with(:name).returns('mylv').twice
      @provider.expects(:dmsetup).with('remove', 'myvg-mylv')
      @provider.expects(:lvremove).with('-f', '/dev/myvg/mylv')
      @provider.destroy
    end
  end
end
