require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class ResourceGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        if namespace_name.empty?
          template "app/resources/template.js.coffee", "#{app_path}/resources/#{file_name}.js.coffee"
        else
          template "app/resources/template_with_namespace.js.coffee", "#{app_path}/resources/#{namespace_path}/#{file_name}.js.coffee"
        end
      end

      protected

      def app_path
        if class_path.size < 1
          puts <<HELP
Usage: rails generate joosy:resource joosy_app_name/resource_name
Tip: resource_name is better to be singular
HELP
          exit 1
        end
        class_path[0]
      end

      def namespace_path
        File.join class_path[1..-1]
      end

      def namespace_name
        class_path[1..-1].map(&:camelize).join '.'
      end
    end
  end
end
