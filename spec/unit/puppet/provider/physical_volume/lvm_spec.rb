require 'spec_helper'

provider_class = Puppet::Type.type(:physical_volume).provider(:lvm)

describe provider_class do
  before do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
  end

  describe 'when creating' do
    it "should execute the 'pvcreate'" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @resource.expects(:[]).with(:force)
      @provider.expects(:pvcreate).with(['/dev/hdx'])
      @provider.create
    end
  end

  describe 'when creating with force' do
    it "should execute the 'pvcreate'" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @resource.expects(:[]).with(:force).returns(:true)
      @provider.expects(:pvcreate).with(['--force','/dev/hdx'])
      @provider.create
    end
  end

  describe 'when destroying' do
    it "should execute 'pvdestroy'" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @provider.expects(:pvremove).with('/dev/hdx')
      @provider.destroy
    end
  end

  describe "when checking existence" do
    it "should execute 'pvs'" do
      @resource.expects(:[]).with(:unless_vg).returns()
      @resource.expects(:[]).with(:name).returns('/dev/sdb')
      @provider.expects(:pvs).returns(true)
      @provider.should be_exists
    end
    it "should not execute 'pvs' if unless_vg VG exists" do
      @resource.expects(:[]).with(:unless_vg).returns('vg01')
      @resource.expects(:[]).with(:unless_vg).returns('vg01')
      @provider.expects(:vgs).returns(true)
      @provider.should be_exists
    end
  end
end
