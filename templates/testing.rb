SOURCE = "vendor/plugins/authlogic_bundle" unless defined? SOURCE
load_template("#{SOURCE}/templates/helper.rb") unless self.respond_to? :file_inject

##############################
# RSpec
##############################
gem 'rspec', :lib => false, :version => '>= 1.2.6', :env => 'test'
gem 'rspec-rails', :lib => false, :version => '>= 1.2.6', :env => 'test'
gem 'remarkable', :lib => false, :version => '>=3.1.2', :env => 'test'
gem 'remarkable_activerecord', :lib => false, :version => '>=3.1.2', :env => 'test'
gem 'remarkable_rails', :lib => false, :version => '>=3.1.2', :env => 'test'
gem 'thoughtbot-shoulda', :lib => false, :version => '>=2.10.1',
  :source => 'http://gems.github.com', :env => 'test'
gem 'thoughtbot-factory_girl', :lib => false, :version => '>=1.2.1',
  :source => 'http://gems.github.com', :env => 'test'

rake 'gems:install', :sudo => true, :env => 'test'
plugin 'object_daddy', :submodule => git?, :git => 'git://github.com/flogic/object_daddy.git'

# plugin 'rspec-rails', :submodule => git?,
#   :git => 'git://github.com/dchelimsky/rspec-rails.git'
# plugin 'rspec', :submodule => git?,
#   :git => 'git://github.com/dchelimsky/rspec.git'
# plugin 'factory_girl', :submodule => git?,
#   :git => 'git://github.com/thoughtbot/factory_girl.git'
# plugin 'shoulda', :submodule => git?,
#   :git => 'git://github.com/thoughtbot/shoulda.git'

generate :rspec

file 'spec/spec.opts', <<-CODE
--colour
--format progress
--format html:coverage/spec.html
--loadby mtime
--reverse
CODE

file_inject 'spec/spec_helper.rb', "require 'spec/rails'", <<-CODE
require 'remarkable_rails'
require 'shoulda'
require 'factory_girl'
CODE

##############################
# Cucumber
##############################
gem 'term-ansicolor', :lib => false, :version => '>=1.0.3', :env => 'test'
gem 'treetop', :lib => false, :version => '>=1.2.5', :env => 'test'
gem 'diff-lcs', :lib => false, :version => '>=1.1.2', :env => 'test'
gem 'nokogiri', :lib => false, :version => '>=1.2.3', :env => 'test'
gem 'builder', :lib => false, :version => '>=2.1.2', :env => 'test'
gem 'cucumber', :lib => false, :version => '>=0.3.5', :env => 'test'
gem 'webrat', :lib => 'webrat', :version => '>=0.4.4', :env => 'test'
gem 'bmabey-email_spec', :lib => 'email_spec', :version => '>=0.1.3',
  :source => 'http://gems.github.com', :env => 'test'
gem 'ruby-debug-base', :lib => false, :version => '>=0.10.3', :env => 'test'
gem 'ruby-debug', :lib => false, :version => '>=0.10.3', :env => 'test'

rake 'gems:install', :sudo => true, :env => 'test'

generate :cucumber

file 'cucumber.yml', <<-CODE
default: -r features features
autotest: -r features --format pretty
autotest-all: -r features --format progress
CODE

file_append 'features/support/env.rb', <<-CODE
require 'email_spec/cucumber'
CODE

generate :email_spec

file 'features/step_definitions/custom_email_steps.rb', <<-CODE
CODE

file_inject 'spec/spec_helper.rb', "require 'spec/rails'", <<-CODE
require 'email_spec/helpers'
require 'email_spec/matchers'
CODE

file_inject 'spec/spec_helper.rb', "Spec::Runner.configure do |config|", <<-CODE
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
CODE

##############################
# RCov & Autotest
##############################
gem 'spicycode-rcov', :lib => 'rcov', :version => '>=0.8.2.1',
  :source => 'http://gems.github.com', :env => 'test'
gem 'ZenTest', :lib => 'autotest', :version => '>=4.0.0', :env => 'test'
gem 'carlosbrando-autotest-notification', :lib => 'autotest_notification', :version => '>=1.9.1',
  :source => 'http://gems.github.com', :env => 'test'

rake 'gems:install', :sudo => true, :env => 'test'

file 'spec/rcov.opts', <<-CODE
--exclude "spec/*,gems/*,features/*"
--rails
--aggregate "coverage.data"
CODE

run 'an-install'
#run 'an-uninstall'

file_append 'config/environments/test.rb', <<-CODE

ENV['AUTOFEATURE'] = "true"
ENV['RSPEC'] = "true"
CODE


if git?
  git :submodule => "init"
  git :submodule => "update"
  git :add => "config lib script spec features cucumber.yml"
  git :commit => "-m 'setup testing suite'"
end
