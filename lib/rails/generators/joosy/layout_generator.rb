require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class LayoutGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        empty_directory "#{app_path}/layouts"
        template "app/layouts/template.js.coffee", "#{app_path}/layouts/#{file_name}.js.coffee"

        empty_directory "#{app_path}/templates/layouts"
        create_file("#{app_path}/templates/layouts/#{file_name}.jst.#{options[:template_kind]}")
      end

      protected

      def app_path
        File.join class_path
      end
    end
  end
end