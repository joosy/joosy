require 'rails/generators/joosy/joosy_base'

module Joosy
  module Generators
    class ApplicationGenerator < ::Rails::Generators::JoosyBase
      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_files
        self.destination_root = "app/assets/javascripts"

        template "app.js.coffee", "#{file_path}.js.coffee"

        empty_directory file_path

        template "app/routes.js.coffee", "#{file_path}/routes.js.coffee"

        empty_directory "#{file_path}/layouts"
        template "app/layouts/application.js.coffee", "#{file_path}/layouts/application.js.coffee"

        empty_directory "#{file_path}/pages"
        template "app/pages/application.js.coffee", "#{file_path}/pages/application.js.coffee"

        empty_directory_with_gitkeep "#{file_path}/widgets"

        empty_directory_with_gitkeep "#{file_path}/templates/layouts"
        empty_directory_with_gitkeep "#{file_path}/templates/pages"
        empty_directory_with_gitkeep "#{file_path}/templates/widgets"
      end
    end
  end
end