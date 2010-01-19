Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:filesystem) do
    before do
        @type = Puppet::Type.type(:filesystem)
        @valid_params = {
            :name => '/dev/myvg/mylv',
            :fstype => 'ext3',
            :size => '1g',
            :ensure => :present
        }
    end

    it "should exist" do
        @type.should_not be_nil
    end

    describe "the name parameter" do
        it "should exist" do
            @type.attrclass(:name).should_not be_nil
        end
        it "should only allow fully qualified files" do
            specifying(:name => 'myfs').should raise_error(Puppet::Error)
        end
        
        it "should support fully qualified names" do
            @type.new(:name => valid_params[:name])[:name].should == valid_params[:name]
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

    describe "autorequiring" do

        it "should guess the logical volume" do
            with(valid_params).must autorequire(:logical_volume, 'mylv')
        end
    
    end


end
