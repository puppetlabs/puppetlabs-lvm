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
            @resource.expects(:[]).with(:ensure).returns('ext3')
            @provider.expects(:execute).with(['mkfs.ext3', '/dev/myvg/mylv'])
            @provider.create
        end
    end

end
