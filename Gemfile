source "http://rubygems.org"

# Specify your gem's dependencies in joosy.gemspec
gemspec

group :development do
  gem 'jasmine',         :git => 'git://github.com/pivotal/jasmine-gem.git'
  gem 'guard-sprockets'
  gem 'thin'
end

group :test do
  gem 'rb-inotify', :require => false
  gem 'libnotify', :require => false
end
