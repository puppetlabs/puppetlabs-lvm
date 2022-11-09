dir = File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(dir, 'lib'))

require 'helpers'
require 'matchers'
require 'singleton'
require 'serverspec'
require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.include Helpers
  config.include Matchers
  c.before :suite do
    pp = <<-MANIFEST
      package { 'lvm2':
        ensure => 'latest',
      }
    MANIFEST
    LitmusHelper.instance.apply_manifest(pp)
  end
end
