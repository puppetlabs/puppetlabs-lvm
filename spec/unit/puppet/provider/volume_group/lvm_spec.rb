Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

provider_class = Puppet::Type.type(:volume_group).provider(:lvm)

describe provider_class do
    before do
        @resource = stub("resource")
        @provider = provider_class.new(@resource)
    end

    describe 'when creating' do
        it "should execute 'vgcreate'" do
            @resource.expects(:[]).with(:name).returns('myvg')
            @resource.expects(:should).with(:physical_volumes).returns(%w{/dev/hda})
            @provider.expects(:vgcreate).with('myvg', '/dev/hda')
            @provider.create
        end
    end

    describe 'when destroying' do
        it "should execute 'vgremove'" do
            @resource.expects(:[]).with(:name).returns('myvg')
            @provider.expects(:vgremove).with('myvg')
            @provider.destroy
        end
    end
end
