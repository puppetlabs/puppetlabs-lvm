Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:volume_group) do
    before do
        @type = Puppet::Type.type(:volume_group)
    end

    it "should exist" do
        Puppet::Type.type(:volume_group).should_not be_nil
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

    describe "the 'physical_volumes' parameter" do
        it "should exist" do
            @type.attrclass(:physical_volumes).should_not be_nil
        end

        it "should support a single value" do
            with(:name => "myvg", :physical_volumes => 'mypv')[:physical_volumes].should == %w{mypv}
        end

        it "should support an array" do
            with(:name => "myvg", :physical_volumes => %w{mypv otherpv})[:physical_volumes].should == %w{mypv otherpv}
        end

        it "should support autorequire a single physical volume" do
            with(:name => "myvg", :physical_volumes => 'mypv').must autorequire(:physical_volume, 'mypv')
        end

        it "should support autorequire multiple physical volumes" do
            with(:name => "myvg", :physical_volumes => %w{mypv otherpv}) do |resource|
                resource.must autorequire(:physical_volume, 'mypv')
                resource.must autorequire(:physical_volume, 'otherpv')
            end
        end
        
    end

    
end
