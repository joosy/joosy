require 'rails/engine'

module Joosy
  module Rails
    class Engine < ::Rails::Engine

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
