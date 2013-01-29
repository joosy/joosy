require 'haml_coffee_assets'
require 'joosy/version'

if defined?(Rails)
  require 'joosy/rails/engine'
  require 'rails/resources_with_joosy'
end

module Joosy
  def self.assets_paths
    [
        File.expand_path('../../app/assets/javascripts', __FILE__),
        File.expand_path('../../vendor/assets/javascripts', __FILE__)
    ]
  end
end