require 'rails/engine'

module Joosy
  def self.resources(namespaces=nil)
    Joosy::SprocketsHelper.joosy_resources(namespaces).to_json
  end

  module Rails
    class Engine < ::Rails::Engine

      cattr_accessor :resources
      self.resources = {}

      initializer 'joosy.extend.sprockets' do |app|
        ActiveSupport.on_load(:action_view) do
          app.assets.context_class.instance_eval do
            include ::Joosy::SprocketsHelper
          end
        end
      end

    end
  end
end
