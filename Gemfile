source "http://rubygems.org"

# Specify your gem's dependencies in joosy.gemspec
gemspec

gem 'jasmine',         :git => 'git://github.com/pivotal/jasmine-gem.git'
gem 'guard-sprockets', :git => 'git://github.com/roundlake/guard-sprockets.git'
gem 'thin'

group :test do
  if RUBY_PLATFORM =~ /linux/
    gem 'rb-inotify'
    gem 'libnotify'
  end
end
