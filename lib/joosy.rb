require 'haml_coffee_assets'
require 'json'

module Joosy
  PACKAGE = File.expand_path("../../package.json", __FILE__)

  # Converting semver to the notation compatible with rubygems
  VERSION = JSON.parse(File.read(PACKAGE))['version'].gsub '-', '.'

  def self.assets_paths
    [
      File.expand_path('../../src', __FILE__),
      File.dirname(HamlCoffeeAssets.helpers_path)
    ]
  end
end