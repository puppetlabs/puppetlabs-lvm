Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

provider_class = Puppet::Type.type(:logical_volume).provider(:lvm)

describe provider_class do

    before do
        @resource = stub("resource")
        @provider = provider_class.new(@resource)
    end

    describe 'when creating' do
        it "should execute 'lvcreate'" do
            @resource.expects(:[]).with(:name).returns('mylv')
            @resource.expects(:[]).with(:volume_group).returns('myvg')
            @resource.expects(:should).with(:size).returns('1g')
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
        end
    end

    describe 'when destroying' do
        it "should execute 'lvremove'" do
            @resource.expects(:[]).with(:volume_group).returns('myvg')
            @resource.expects(:[]).with(:name).returns('mylv')
            @provider.expects(:lvremove).with('/dev/myvg/mylv')
            @provider.destroy
        end
    end

    describe "when changing the size" do

        describe "to a defined value" do

            it "should call lvextend and related commands" do
                @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
                @resource.expects(:[]).with(:name).returns('mylv').at_least_once
                @provider.expects(:umount).with('/dev/myvg/mylv')
                @provider.expects(:lvextend).with('--size', '2g', '/dev/myvg/mylv')
                @provider.expects(:mount).with('/dev/myvg/mylv')
                # TODO: Test filesystem resizing?
                @provider.size = '2g'
            end

        end

        describe "to undef" do

            it "should extend the logical volume to fill all avialable space" do
                pending
            end

        end
        
    end
    
end
