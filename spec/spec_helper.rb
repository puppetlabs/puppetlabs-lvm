dir = File.expand_path(File.dirname(__FILE__))

$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/lib") # a spec-specific test lib dir
$LOAD_PATH.unshift("#{dir}/../lib")

require 'mocha'
require 'puppet'
gem 'rspec', '=1.2.9'
require 'spec/autorun'

module Helpers
    TYPEMAP = {:pv => :physical_volume, :lv => :logical_volume, :vg => :volume_group}
    def with(opts = {})
        @type.new(opts)
    end 

    def specifying(opts = {})
        lambda { with(opts) }
    end 

    def should_not_create(type)
        raise "Invalid type #{type}" unless TYPEMAP[type]
        Puppet::Type.type(TYPEMAP[type]).expects(:new).never
    end

    def should_create(type)
        raise "Invalid type #{type}" unless TYPEMAP[type]
        Puppet::Type.type(TYPEMAP[type]).expects(:new).with { |args| yield(args) }
    end
end 


Spec::Runner.configure do |config|
    config.mock_with :mocha
    config.include Helpers
end

# We need this because the RAL uses 'should' as a method.  This
# allows us the same behaviour but with a different method name.
class Object
    alias :must :should
end
