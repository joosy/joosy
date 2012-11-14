source "http://rubygems.org"

# Specify your gem's dependencies in joosy.gemspec
gemspec

group :development do
  gem 'jasmine',         :git => 'git://github.com/pivotal/jasmine-gem.git'
  gem 'guard-sprockets', :git => 'git://github.com/guard/guard-sprockets.git'
  gem 'thin'
end

group :test do
  if RUBY_PLATFORM =~ /linux/
    gem 'rb-inotify'
    gem 'libnotify'
  end
end
