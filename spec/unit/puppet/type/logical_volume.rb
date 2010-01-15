Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:logical_volume) do
    before do
        @type = Puppet::Type.type(:logical_volume)
        @valid_params = {
            :name => 'mylv',
            :fstype => 'ext3',
            :volume_group => 'myvg',
            :size => '1g',
            :ensure => :present,
            :physical_volumes => %w{/disk/1 /disk/2}
        }
    end

    it "should exist" do
        @type.should_not be_nil
    end

    it "should be depth-first" do
        @type.should be_depthfirst
    end

    describe "when specifying the name parameter" do
        it "should exist" do
            @type.attrclass(:name).should_not be_nil
        end

        it "should not allow qualified files" do
            lambda { @type.new :name => "my/lv" }.should raise_error(Puppet::Error)
        end
        
        it "should support unqualified names" do
            @type.new(:name => "mylv")[:name].should == "mylv"
        end
    end

    describe "when specifying the volume_group parameter" do
        before do
            @vgtype = Puppet::Type.type(:volume_group)
        end

        it "should not create a volume group if not specified" do
            should_not_create(:vg)
            with(valid_params_without(:volume_group))
        end

        it "should create a volume group if specified at initialization" do
            should_create(:vg) { |args| args[:name] == "myvg" }
            with(valid_params)
        end

        it "should include its physical volumes when creating the volume group if physical volumes are specified" do
            should_create(:vg) { |args| args[:name] == "myvg" }
            with(valid_params)
        end

        it "should configure the volume group for creation if the logical volume should exist" do
            should_create(:vg) { |args| args[:ensure] == :present }
            with(valid_params.merge(:ensure => :present))
        end

        it "should configure the volume group for deletion if the logical volume should not exist" do
            should_create(:vg) { |args| args[:ensure] == :absent }
            with(valid_params.merge(:ensure => :absent))
        end

        it "should not create volume groups if 'ensure' was not specified on the logical volume" do
            should_not_create(:vg)
            with(valid_params_without(:ensure))
        end

        it "should return a volume group instance when generating resources" do
            resource = with(valid_params)
            resource.generate.detect { |resource| resource.is_a?(@vgtype) }.should_not be_nil
        end

        it "should generate the resources from the volume group when generating a volume group" do
            resource = with(valid_params)
            resource.generate.detect { |resource| resource.is_a?(Puppet::Type.type(:physical_volume)) }.should_not be_nil
        end

        it "should return nil when no resources were generated" do
            resource = with(valid_params_without(:volume_group))
            resource.generate.detect { |resource| resource.is_a?(@vgtype) }.should be_nil
        end

        it "should support specifying a volume_group" do
            should_create(:vg) { |args| args[:name] == "my_vg" }
            with(valid_params.merge(:volume_group => "my_vg"))
        end
    end
    
    describe "when specifying the 'ensure' parameter" do
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

        it "should return a filesystem when generating resources" do
            resource = with(valid_params)
            resource.generate.detect { |resource| resource.is_a?(@fstype) }.should_not be_nil
        end

        it "should return nil when no resources were generated" do
            resource = with(valid_params_without(:fstype))
            resource.generate.detect { |resource| resource.is_a?(@fstype) }.should be_nil
        end

        it "should support specifying a filesystem" do
            should_create(:fs) { |args| args[:fstype] == 'ext3' }
            with(valid_params.merge(:fstype => 'ext3'))
        end

    end
end
