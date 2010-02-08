Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

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
                @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
                @provider.create
            end
        end
        context 'without size' do
            it "should execute 'lvcreate' without a '--size' option" do
                @resource.expects(:[]).with(:name).returns('mylv')
                @resource.expects(:[]).with(:volume_group).returns('myvg')
                @resource.expects(:[]).with(:size).returns(nil).at_least_once
                @provider.expects(:lvcreate).with('-n', 'mylv', 'myvg')
                @provider.create
            end
        end
    end

    describe 'when destroying' do
        it "should execute 'lvremove'" do
            @resource.expects(:[]).with(:volume_group).returns('myvg')
            @resource.expects(:[]).with(:name).returns('mylv')
            @provider.expects(:lvremove).with('-f', '/dev/myvg/mylv')
            @provider.destroy
        end
    end
end
