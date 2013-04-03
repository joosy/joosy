require 'rails/generators/named_base'

module Joosy
  module Generators
    class PreloaderGenerator < ::Rails::Generators::NamedBase
      class_option :template_engine, :type => :string,
        :desc => "Generate templates for specified engine."

      source_root File.join(File.dirname(__FILE__), 'templates')

      def create_preloader_files
        unless class_path.empty?
          puts <<HELP
Usage: rails generate joosy:preloader joosy_app_name
HELP
          exit 1
        end

        template "app_preloader.js.coffee.erb", "app/assets/javascripts/#{file_name}_preloader.js.coffee.erb"

        template "app_controller.rb", "app/controllers/#{file_name}_controller.rb"

        template "preload.html.#{options[:template_engine]}",
                 "app/views/layouts/#{file_name}.html.#{options[:template_engine]}"

        route "get '#{file_name}' => '#{file_name}#index'"
      end
    end
  end
end