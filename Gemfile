source "https://rubygems.org"

group :development, :test do
  gem 'rake'
  gem 'rspec', "~> 3.1.0", :require => false
  gem 'mocha', "~> 0.10.5", :require => false
  gem 'puppetlabs_spec_helper', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'puppet-lint', '>= 0.3.2'
# vim:ft=ruby
