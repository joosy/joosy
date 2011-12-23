require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class WidgetGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        empty_directory "#{app_path}/widgets"
        template "widgets/template.js.coffee", "#{app_path}/widgets/#{file_name}.js.coffee"

        empty_directory "#{app_path}/templates/widgets"
        create_file "#{app_path}/templates/widgets/#{file_name}.jst.#{options[:template_kind]}"
      end

      protected

      def app_path
        File.join class_path
      end
    end
  end
end