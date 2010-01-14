Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:volume_group) do
    before do
        @type = Puppet::Type.type(:volume_group)
    end

    it "should exist" do
        Puppet::Type.type(:volume_group).should_not be_nil
    end

    it "should be depth-first" do
        Puppet::Type.type(:volume_group).should be_depthfirst
    end

    describe "the name parameter" do
        it "should exist" do
            @type.attrclass(:name).should_not be_nil
        end
    end

    describe "the 'ensure' parameter" do
        it "should exist" do
            @type.attrclass(:ensure).should_not be_nil
        end

        it "should support 'present' as a value" do
            with(:name => "myvg", :ensure => :present)[:ensure].should == :present
        end

        it "should support 'absent' as a value" do
            with(:name => "myvg", :ensure => :absent)[:ensure].should == :absent
        end

        it "should not support other values" do
            specifying(:name => "myvg", :ensure => :foobar).should raise_error(Puppet::Error)
        end
    end

    describe "when managing physical volumes" do
        before do
            @pvtype = Puppet::Type.type(:physical_volume)
        end

        it "should not create physical volumes if none are specified" do
            should_not_create(:pv)
            with(:name => "myvg", :ensure => :present)
        end

        it "should create a physical volume for each specified name at initialization" do
            should_create(:pv) { |args| args[:name] == "/my/pv" }
            with(:name => "myvg", :physical_volumes => %w{/my/pv}, :ensure => :present)
        end

        it "should configure the physical volumes for creation if the volume group should exist" do
            should_create(:pv) { |args| args[:ensure] == :present }
            with(:name => "myvg", :physical_volumes => %w{/my/pv}, :ensure => :present)
        end

        it "should configure the physical volumes for deletion if the volume group should not exist" do
            should_create(:pv) { |args| args[:ensure] == :absent }
            with(:name => "myvg", :physical_volumes => %w{/my/pv}, :ensure => :absent)
        end

        it "should not create physical volumes if 'ensure' was not specified on the volume group" do
            should_not_create(:pv)
            with(:name => "myvg", :physical_volumes => %w{/my/pv})
        end

        it "should return all created volume resources when generating resources" do
            resource = with(:name => "myvg", :physical_volumes => %w{/my/pv}, :ensure => :present)
            resource.generate[0].should be_instance_of(@pvtype)
        end

        it "should return nil when no resources were generated" do
            with(:name => "myvg", :ensure => :present).generate.should be_nil
        end

        it "should support specifying a single volume" do
            should_create(:pv) { |args| args[:name] == "/my/pv" }
            with(:name => "myvg", :physical_volumes => "/my/pv", :ensure => :present)
        end

        it "should support specifying an array of volumes" do
            should_create(:pv) { |args| args[:name] == "/my/pv" }
            with(:name => "myvg", :physical_volumes => %w{/my/pv}, :ensure => :present)
        end
    end
end
