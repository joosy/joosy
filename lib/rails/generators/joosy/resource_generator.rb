require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class ResourceGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        empty_directory "#{app_path}/resources"
        template "app/resources/template.js.coffee", "#{app_path}/resources/#{file_name}.js.coffee"
      end

      protected

      def app_path
        unless class_path.size == 1
          puts <<HELP
Usage: rails generate joosy:resource joosy_app_name/resource_name
Tip: resource_name is better to be singular
HELP
          exit 1
        end
        class_path[0]
      end
    end
  end
end