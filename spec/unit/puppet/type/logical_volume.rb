Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

describe Puppet::Type.type(:logical_volume) do
    it "should exist" do
        Puppet::Type.type(:logical_volume).should_not be_nil
    end

    it "should have a 'name' parameter" do
        Puppet::Type.type(:logical_volume).attrclass(:name).should_not be_nil
    end
end
