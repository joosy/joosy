require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class PageGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        empty_directory "#{app_path}/pages"
        template "app/pages/template.js.coffee", "#{app_path}/pages/#{layout_name}/#{file_name}.js.coffee"

        empty_directory "#{app_path}/templates/pages/#{layout_name}"
        create_file "#{app_path}/templates/pages/#{layout_name}/#{file_name}.jst.#{options[:template_kind]}"
      end

      protected

      def app_path
        File.join class_path[0..-2]
      end

      def layout_name
        class_path.last
      end
    end
  end
end