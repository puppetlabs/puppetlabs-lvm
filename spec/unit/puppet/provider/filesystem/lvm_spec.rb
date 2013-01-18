Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

provider_class = Puppet::Type.type(:filesystem).provider(:lvm)

describe provider_class do
    before do
        @resource = stub("resource")
        @provider = provider_class.new(@resource)
    end

    describe 'when creating' do
        it "should execute the correct filesystem command" do
            @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
            @resource.expects(:[]).with(:fs_type).returns('ext4')
            @resource.expects(:[]).with(:options)
            @provider.expects(:execute).with(['mkfs.ext4', '/dev/myvg/mylv'])
            @provider.create
        end
        it "should include the supplied filesystem options" do
            @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
            @resource.expects(:[]).with(:fs_type).returns('ext4')
            @resource.expects(:[]).with(:options).returns('-b 4096 -E stride=32,stripe-width=64').twice
            @provider.expects(:execute).with(['mkfs.ext4', '/dev/myvg/mylv', ['-b', '4096', '-E', 'stride=32,stripe-width=64']])
            @provider.create
        end
        it "should include -q for reiserfs" do
            @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
            @resource.expects(:[]).with(:fs_type).returns('reiserfs')
            @resource.expects(:[]).with(:options).returns('-b 4096 -E stride=32,stripe-width=64').twice
            @provider.expects(:execute).with(['mkfs.reiserfs', '/dev/myvg/mylv', '-q', ['-b', '4096', '-E', 'stride=32,stripe-width=64']])
            @provider.create
        end
    end

end
