require 'rubygems'
require 'json'

package = JSON.parse File.read(File.expand_path("../package.json", __FILE__))

Gem::Specification.new do |s|
  s.name = "joosy"
  s.version = package['version'].gsub('-', '.')
  s.platform = Gem::Platform::RUBY
  s.summary = package['description']
  s.email = "boris@staal.io"
  s.homepage = "http://github.com/joosy/joosy"
  s.description = "A gem wrapper to include Joosy via the asset pipeline"
  s.authors = ['Boris Staal', 'Andrew Shaydurov', 'Peter Zotov', 'Alexander Pavlenko']

  s.files = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'sprockets'
  s.add_dependency 'haml_coffee_assets'
end