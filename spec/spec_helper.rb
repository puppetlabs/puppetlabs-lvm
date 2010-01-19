dir = File.expand_path(File.dirname(__FILE__))

$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/lib") # a spec-specific test lib dir
$LOAD_PATH.unshift("#{dir}/../lib")

require 'mocha'
require 'puppet'
gem 'rspec', '=1.2.9'
require 'spec/autorun'

module Helpers
    
    TYPES = {
        :pv => :physical_volume,
        :lv => :logical_volume,
        :vg => :volume_group,
        :fs => :filesystem
    }

    def self.included(obj)
        obj.instance_eval { attr_reader :valid_params }
    end

    # Creates a new resource of +type+
    def with(opts = {}, &block)
        resource = @type.new(opts)
        block ? (yield resource) : resource
    end 

    # Returns a lambda creating a resource (ready for use with +should+)
    def specifying(opts = {}, &block)
        specification = lambda { with(opts) }
        block ? (yield specification) : specification
    end 

    # Sets up an expection that a resource for +type+ is not created    
    def should_not_create(type)
        raise "Invalid type #{type}" unless TYPES[type]
        Puppet::Type.type(TYPES[type]).expects(:new).never
    end

    # Sets up an expection that a resource for +type+ is created
    def should_create(type)
        raise "Invalid type #{type}" unless TYPES[type]
        Puppet::Type.type(TYPES[type]).expects(:new).with { |args| yield(args) }
    end

    # Return the +@valid_params+ without one or more keys
    # Note: Useful since resource types don't like it when +nil+ is
    # passed as a parameter value
    def valid_params_without(*keys)
        valid_params.reject { |k, v| keys.include?(k) }
    end
    
end

module Matchers

    class AutoRequireMatcher
        def initialize(*expected)
            @expected = expected
        end

        def matches?(resource)
            resource_type = resource.class
            configuration = resource_type.instance_variable_get(:@autorequires) || {}
            @autorequires = configuration.inject([]) do |memo, (param, block)|
                memo + resource.instance_eval(&block)
            end
            @autorequires.include?(@expected)
        end
        def failure_message_for_should
            "expected resource autorequires (#{@autorequires.inspect}) to include #{@expected.inspect}"
        end
        def failure_message_for_should_not
            "expected resource autorequires (#{@autorequires.inspect}) to not include #{@expected.inspect}"
        end
    end

    # call-seq:
    #   autorequire :logical_volume, 'mylv'
    def autorequire(type, name)
        AutoRequireMatcher.new(type, name)
    end
    
end

Spec::Runner.configure do |config|
    config.mock_with :mocha
    config.include Helpers
    config.include Matchers
end

# We need this because the RAL uses 'should' as a method.  This
# allows us the same behaviour but with a different method name.
class Object
    alias :must :should
end
