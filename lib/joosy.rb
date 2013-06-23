require 'json'

begin
  require 'haml_coffee_assets'
rescue Gem::LoadError # This is required for the first bundle run
end

module Joosy
  PACKAGE = File.expand_path("../../package.json", __FILE__)

  # Converting semver to the notation compatible with rubygems
  VERSION = JSON.parse(File.read(PACKAGE))['version'].gsub '-', '.'

  def self.assets_paths
    [
      File.expand_path('../../src', __FILE__)
    ]
  end

  def self.generators_path
    File.expand_path '../../src/joosy/generators', __FILE__
  end

  def self.templates_path
    File.expand_path '../../templates', __FILE__
  end
end