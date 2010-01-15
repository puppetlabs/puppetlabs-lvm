Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:logical_volume) do
    before do
        @type = Puppet::Type.type(:logical_volume)
        @valid_params = {
            :name => 'mylv',
            :fstype => 'ext3',
            :volume_group => 'myvg',
            :size => '1g',
            :ensure => :present
        }
    end

    it "should exist" do
        @type.should_not be_nil
    end

    it "should be depth-first" do
        @type.should be_depthfirst
    end

    describe "the name parameter" do
        it "should exist" do
            @type.attrclass(:name).should_not be_nil
        end
    end

    describe "the volume_group parameter" do
        it "should exist" do
            @type.attrclass(:volume_group).should_not be_nil
        end
    end
    
    describe "the 'ensure' parameter" do
        it "should exist" do
            @type.attrclass(:ensure).should_not be_nil
        end

        it "should support 'present' as a value" do
            with(valid_params)[:ensure].should == :present
        end

        it "should support 'absent' as a value" do
            with(valid_params.merge(:ensure => :absent))[:ensure].should == :absent
        end

        it "should not support other values" do
            specifying(valid_params.merge(:ensure => :foobar)).should raise_error(Puppet::Error)
        end
    end


    describe "when managing a filesystem" do
        before do
            @fstype = Puppet::Type.type(:filesystem)
        end

        it "should not create filesystems if not specified" do
            should_not_create(:fs)
            with(valid_params_without(:fstype))
        end

        it "should create a filesystem if specified at initialization" do
            should_create(:fs) { |args| args[:name] == "/dev/myvg/mylv" }
            with(valid_params)
        end

        it "should configure the filesystems for creation if the logical volume should exist" do
            should_create(:fs) { |args| args[:ensure] == :present }
            with(valid_params.merge(:ensure => :present))
        end

        # NOTE: Not sure "deleting a filesystem" is possible/makes
        # sense -BW
        it "should configure the filesystem for deletion if the logical volume should not exist" do
            should_create(:fs) { |args| args[:ensure] == :absent }
            with(valid_params.merge(:ensure => :absent))
        end

        it "should not create filesystems if 'ensure' was not specified on the logical volume" do
            should_not_create(:fs)
            with(valid_params_without(:ensure))
        end

        it "should return filesystem  when generating resources" do
            resource = with(valid_params)
            resource.generate[0].should be_instance_of(@fstype)
        end

        it "should return nil when no resources were generated" do
            with(valid_params_without(:fstype)).generate.should be_nil
        end

        it "should support specifying a filesystem" do
            should_create(:fs) { |args| args[:fstype] == 'ext3' }
            with(valid_params.merge(:fstype => 'ext3'))
        end

    end
end
