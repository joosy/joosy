require 'haml_coffee_assets'
require 'jquery-rails'
require 'coffee-rails'

require 'joosy/version'

if defined?(Rails)
  require 'joosy/rails/engine'
  require 'rails/resources_with_joosy'
end

require 'i18n-js'

module Joosy
  def self.resources(namespaces=nil)
    Joosy::SprocketsHelper.joosy_resources(namespaces).to_json
  end
end