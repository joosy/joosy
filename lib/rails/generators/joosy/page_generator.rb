require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class PageGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        ::FileUtils.mkdir_p "#{app_path}/pages/#{namespace_path}" if behavior != :revoke
        template "app/pages/template.js.coffee", "#{app_path}/pages/#{namespace_path}/#{file_name}.js.coffee"

        ::FileUtils.mkdir_p "#{app_path}/templates/pages/#{namespace_path}" if behavior != :revoke
        create_file "#{app_path}/templates/pages/#{namespace_path}/#{file_name}.jst.#{options[:template_kind]}"
      end

      protected

      def app_path
        if class_path.size < 2
          puts <<HELP
Usage: rails generate joosy:page joosy_app_name/page_namespace/page_name
Tip: do not add Page suffix to page_name
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

      def layout_name
        class_path[1]
      end
    end
  end
end