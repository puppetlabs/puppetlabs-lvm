Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

provider_class = Puppet::Type.type(:physical_volume).provider(:lvm)

describe provider_class do
    before do
        @resource = stub("resource")
        @provider = provider_class.new(@resource)
    end

    describe 'when creating' do
        it "should execute the 'pvcreate'" do
            @resource.expects(:[]).with(:name).returns('/dev/hdx')
            @provider.expects(:pvcreate).with('/dev/hdx')
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
            @resource.expects(:[]).with(:name).returns('/dev/sdb')
            @provider.expects(:pvs).returns(fixture(:pvs))
            @provider.should be_exists
        end
    end
end
