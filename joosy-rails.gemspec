require File.expand_path("../lib/joosy/rails/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "joosy-rails"
  s.version     = Joosy::Rails::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Joosy on Rails"
  s.email       = "boris@roundlake.ru"
  s.homepage    = "http://github.com/roundlake/joosy-rails"
  s.description = "A gem wrapper to include Joosy via the asset pipeline."
  s.authors     = ['Boris Staal', 'Peter Zotov']

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'rails', ">= 3.0.0"
  s.add_dependency 'coffee-rails'
  s.add_dependency 'jquery-rails'
end
