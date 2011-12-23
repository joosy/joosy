require 'rails/generators/named_base'

module Joosy
  module Generators
    class PreloaderGenerator < ::Rails::Generators::NamedBase
      class_option :template_engine, :type => :string,
                                     :desc => "Generate templates for specified engine."

      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_preloader_files
        template "app_preloader.js.coffee", "app/assets/javascripts/#{file_path}_preloader.js.coffee"

        empty_directory "app/controllers/#{File.join class_path}"
        template "app_controller.rb", "app/controllers/#{file_path}_controller.rb"

        empty_directory "app/views/layouts/#{File.join class_path}"
        template "preload.html.#{options[:template_engine]}",
                 "app/views/layouts/#{file_path}.html.#{options[:template_engine]}"

        route "match '#{file_path}' => '#{file_path}#index'"
      end
    end
  end
end