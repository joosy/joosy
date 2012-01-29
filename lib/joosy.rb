require 'haml_coffee_assets'
require 'jquery-rails'
require 'coffee-rails'

require 'joosy/rails/engine'
require 'joosy/rails/version'
require 'joosy/forms'

ActionController::Base.send :include, Joosy::Forms