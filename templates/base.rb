SOURCE = "vendor/plugins/authlogic_bundle"
load_template("#{SOURCE}/templates/helper.rb")

#########################
#  Gems & Plugins
#########################

rake 'db:sessions:create'
file_append 'config/initializers/session_store.rb', <<-CODE
ActionController::Base.session_store = :active_record_store
CODE


if yes?("Install haml?")
  haml, type = true, "haml"
  if `gem list haml | grep 2.1.0`.chomp == ''
    unless File.exist?('tmp/haml')
      inside('tmp') do
        run 'rm -rf ./haml' if File.exist?('haml')
        run 'git clone git://github.com/nex3/haml.git'
      end
    end

    inside('tmp/haml') do
      run 'rake install'
    end
  end

  run 'echo N\n | haml --rails .'
  run 'mkdir -p public/stylesheets/sass'
  %w( main reset ).each do |file|
    file "public/stylesheets/sass/#{file}.sass",
      open("#{SOURCE}/public/stylesheets/sass/#{file}.sass").read
  end
end

# please note the order of config.gem and databse migration
gem 'stffn-declarative_authorization', :lib => 'declarative_authorization',
  :version => '>=0.3.0', :source => 'http://gems.github.com'
gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.6'
gem 'authlogic-oid', :lib => 'authlogic_openid', :version => '>=1.0.3'
gem 'authlogic', :version => '>=2.0.13'
gem 'bcrypt-ruby', :lib => 'bcrypt', :version => '>=2.0.5'

rake 'gems:install', :sudo => true

# plugin 'authlogic', :submodule => git?, 
#   :git => 'git://github.com/binarylogic/authlogic.git'

# plugin 'declarative_authorization', :submodule => git?,
#   :git => 'git://github.com/stffn/declarative_authorization.git'

plugin 'open_id_authentication', :submodule => git?, 
  :git => 'git://github.com/rails/open_id_authentication.git'
plugin 'ssl_requirement', :submodule => git?,
  :git => 'git://github.com/rails/ssl_requirement.git'
plugin 'i18n_label', :submodule => git?,
  :git => 'git://github.com/iain/i18n_label.git'
plugin 'custom-err-msg', :submodule => git?, :git => 'git://github.com/gumayunov/custom-err-msg.git'
plugin 'validation_reflection', :submodule => git?, :git  => 'git://github.com/redinger/validation_reflection.git'
plugin 'vasco', :submodule => git?, :git => 'git://github.com/relevance/vasco.git'
plugin 'excessive_support', :submodule => git?, :git => 'git://github.com/yizzreel/excessive_support.git'

generate :migration, 'create_users'
file Dir.glob('db/migrate/*_create_users.rb').first,
  open("#{SOURCE}/db/migrate/create_users.rb").read

generate :migration, 'add_open_id_to_users'
file Dir.glob('db/migrate/*_add_open_id_to_users.rb').first,
  open("#{SOURCE}/db/migrate/add_open_id_to_users.rb").read
rake 'open_id_authentication:db:create'

generate :migration, 'create_roles'
file Dir.glob('db/migrate/*_create_roles.rb').first,
  open("#{SOURCE}/db/migrate/create_roles.rb").read

rake 'db:migrate'#, :env => 'development'

#########################
#  Configuration
#########################
route "map.root :controller => 'home', :action => 'index'"
route "map.resources :users"
route "map.resources :roles"

file_append 'config/locales/en.yml', open("#{SOURCE}/config/locales/en.yml").read
file_append 'config/locales/zh-CN.yml', open("#{SOURCE}/config/locales/zh-CN.yml").read
file_append 'config/locales/zh-TW.yml', open("#{SOURCE}/config/locales/zh-TW.yml").read

file_append 'config/authorization_rules.rb', open("#{SOURCE}/config/authorization_rules.rb").read

file_append 'config/notifier.yml', <<-CODE
development:
  notifier:
    host: localhost:3000
    name: User Notifier
    email: noreply@example.com

test:
  notifier:
    host: www.example.com
    name: User Notifier
    email: noreply@example.com

production:
  notifier:
    host: www.example.com
    name: User Notifier
    email: noreply@example.com

CODE

# initializer 'config_loader.rb'
file_append 'config/initializers/config_loader.rb', <<-CODE
config = File.read(Rails.root.join('config', 'notifier.yml'))
NOTIFIER = YAML.load(config)[RAILS_ENV]['notifier'].symbolize_keys
CODE

#########################
#  MVC
#########################

# Controllers
file_inject 'app/controllers/application_controller.rb',
  'class ApplicationController < ActionController::Base', <<-CODE
  include AuthenticatedSystem
  include AuthorizedSystem
  include LocalizedSystem
  include SslRequirement

  def ssl_required?
    return ENV['SSL'] == 'on' ? true : false if defined? ENV['SSL']
    return false if local_request?
    return false if RAILS_ENV == 'test'
    super
  end
CODE

# Helpers
# NOTE: Only controller's helper in engines will be loaded.
file_inject 'app/helpers/application_helper.rb', 'module ApplicationHelper', <<-CODE
  def secure_mail_to(email, name = nil)
    return name if email.blank?
    mail_to email, name, :encode => 'javascript'
  end

  def at(klass, attribute, options = {})
    klass.human_attribute_name(attribute.to_s, options = {})
  end

  def openid_link
    link_to at(User, :openid_identifier), "http://openid.net/"
  end
CODE

file_append 'app/helpers/layout_helper.rb', open("#{SOURCE}/app/helpers/layout_helper.rb").read

#Install jQuery
  #clean up prototype files
  inside('public/javascripts') do
    %w(
      application.js
      controls.js
      dragdrop.js
      effects.js
      prototype.js
    ).each do |file|
      run "rm -f #{file}"
    end
  end

  file 'public/javascripts/jquery.js',
    open('http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.min.js').read
  file 'public/javascripts/jquery.full.js',
    open('http://ajax.googleapis.com/ajax/libs/jquery/1.3/jquery.js').read
  file 'public/javascripts/jquery-ui.js',
    open('http://ajax.googleapis.com/ajax/libs/jqueryui/1.5/jquery-ui.min.js').read
  file 'public/javascripts/jquery-ui.full.js',
    open('http://ajax.googleapis.com/ajax/libs/jqueryui/1.5/jquery-ui.js').read
  file 'public/javascripts/jquery.form.js',
    open('http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js').read

  file "public/javascripts/application.js", <<-JS
  $(function() {
  });
  JS

if git?
  git :rm => "public/index.html"
  git :submodule => "init"
  git :submodule => "update"
  git :add => "app config db"
  git :commit => "-m 'install authlogic bundle'"
else
  run 'rm public/index.html'
end
