require 'spec_helper'

describe Puppet::Type.type(:logical_volume) do
  before do
    @type = Puppet::Type.type(:logical_volume)
    @valid_params = {
      :name => 'mylv',
      :volume_group => 'myvg',
      :size => '1g',
      :extents => '80%vg',
      :ensure => :present,
      :size_is_minsize => :false,
    }
    stub_default_provider!
      end

  it "should exist" do
    @type.should_not be_nil
  end

  describe "when specifying the 'name' parameter" do
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

  describe "when specifying the 'volume_group' parameter" do
    it "should exist" do
      @type.attrclass(:volume_group).should_not be_nil
    end
  end

  describe "when specifying the 'size' parameter" do
    it "should exist" do
      @type.attrclass(:size).should_not be_nil
    end
    it 'should support setting a value' do
      with(valid_params)[:size].should == valid_params[:size]
    end
  end

  describe "when specifying the 'size_is_minsize' parameter" do
    it "should exist" do
      @type.attrclass(:size_is_minsize).should_not be_nil
    end
    it 'should support setting a value' do
      with(valid_params)[:size_is_minsize].should == valid_params[:size_is_minsize]
    end
    it "should support 'true' as a value" do
      with(valid_params.merge(:size_is_minsize => :true)) do |resource|
        resource[:size_is_minsize].should == :true
        end
      end
    it "should support 'false' as a value" do
      with(valid_params.merge(:size_is_minsize => :false)) do |resource|
        resource[:size_is_minsize].should == :false
        end
      end
    it "should not support other values" do
      specifying(valid_params.merge(:size_is_minsize => :moep)).should raise_error(Puppet::Error)
      end
  end

  describe "when specifying the 'extents' parameter" do
    it "should exist" do
      @type.attrclass(:extents).should_not be_nil
    end
    it 'should support setting a value' do
      with(valid_params)[:extents].should == valid_params[:extents]
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
      with(valid_params.merge(:ensure => :absent)) do |resource|
        resource[:ensure].should == :absent
        end
      end
    it "should not support other values" do
      specifying(valid_params.merge(:ensure => :foobar)).should raise_error(Puppet::Error)
      end
  end
end
