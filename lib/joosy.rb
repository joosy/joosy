require 'joosy/rails/engine'
require 'joosy/rails/version'
require 'joosy/forms'

ActionController::Base.send :include, Joosy::Forms