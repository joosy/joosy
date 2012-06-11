require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class WidgetGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        super

        template "app/widgets/template.js.coffee", "#{app_path}/widgets/#{file_name}.js.coffee"

        create_file "#{app_path}/templates/widgets/#{file_name}.jst.#{options[:template_kind]}"
      end

      protected

      def app_path
        unless class_path.size == 1
          puts <<HELP
Usage: rails generate joosy:widget joosy_app_name/widget_name
Tip: do not add Widget suffix to widget_name
HELP
          exit 1
        end
        class_path[0]
      end
    end
  end
end