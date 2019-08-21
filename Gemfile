source "https://rubygems.org"

group :development, :test do
  gem 'rake'
  gem 'rspec', "~> 3.4.0",      :require => false
  gem 'mocha', "~> 0.10.5",     :require => false
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-blacksmith',      :require => false
	gem 'puppet_litmus', 					:require => false
	gem 'parallel',			 					:require => false
	gem 'serverspec',			 					:require => false
	gem 'pry',			 					:require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'puppet-lint', '>= 1.0.0'
gem 'puppet-lint-unquoted_string-check', :require => false
gem 'public_suffix', '1.4.6',            :require => false if RUBY_VERSION <= '1.9.3'
gem 'public_suffix',                     :require => false if RUBY_VERSION > '1.9.3'
gem 'json',      '<= 1.8'   ,            :require => false if RUBY_VERSION < '2.0.0'
gem 'json_pure', '<= 2.0.1' ,            :require => false if RUBY_VERSION < '2.0.0'
gem 'metadata-json-lint', '0.0.11',      :require => false if RUBY_VERSION < '1.9'
gem 'metadata-json-lint',                :require => false if RUBY_VERSION >= '1.9'

if RUBY_VERSION < '2.0'
      gem 'mime-types', '<3.0', :require => false
end
