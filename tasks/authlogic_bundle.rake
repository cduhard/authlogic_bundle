$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')

namespace :authlogic_bundle do
  plugin_path = "vendor/plugins/authlogic_bundle"

  desc "Sync bundled files"
  task :sync do
    system "rsync -rbv #{plugin_path}/app/helpers/application_helper.rb app/helpers"
    system "rsync -rbv #{plugin_path}/app/helpers/layout_helper.rb app/helpers"
    system "rsync -ruv #{plugin_path}/config/authorization_rules.rb config"
    system "rsync -ruv #{plugin_path}/config/initializers config"
    system "rsync -ruv #{plugin_path}/config/notifier.yml config"
    system "rsync -rbv #{plugin_path}/config/locales config"
    system "rsync -ruv #{plugin_path}/cucumber.yml ."
    # system "rsync -ruv #{plugin_path}/public ."
  end

  begin
    require 'cucumber/rake/task'

    Cucumber::Rake::Task.new(:features, "Run Features of authlogic_bundle with Cucumber") do |t|
      t.cucumber_opts = %w{--format pretty}
      t.feature_pattern = "#{plugin_path}/features/**/*.feature"
      t.step_pattern = "#{plugin_path}/features/**/*.rb"
    end
    task :features => 'db:test:prepare'
  rescue LoadError
    desc 'Cucumber rake task not available'
    task :features do
      abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
    end
  end
end
