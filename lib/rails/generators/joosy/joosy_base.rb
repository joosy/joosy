require 'rails/generators/named_base'

module Rails
  module Generators
    class JoosyBase < ::Rails::Generators::NamedBase
      class_option :template_kind, :type => :string, :aliases => "-T", :default => 'hamlc',
                                   :desc => "Generate templates with specified extension (default: .hamlc)"

      class_option :skip_git,      :type => :boolean, :aliases => "-G", :default => false,
                                   :desc => "Skip Git keeps"


      def create_files
        self.destination_root = "app/assets/javascripts"
      end

      protected

      # From https://github.com/rails/rails/blob/master/railties/lib/rails/generators/app_base.rb
      def empty_directory_with_gitkeep(destination, config = {})
        empty_directory(destination, config)
        git_keep(destination)
      end

      def git_keep(destination)
        create_file("#{destination}/.gitkeep") unless options[:skip_git]
      end
    end
  end
end
