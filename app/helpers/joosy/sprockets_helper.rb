require 'uri'

module Joosy::SprocketsHelper
  def extract_sources_and_sizes_from_include_tag(name)
    code = javascript_include_tag name
    resources = code.scan(/(?:href|src)=['"]([^'"]+)['"]/).flatten

    resources.map do |resource|
      uri  = URI.parse resource
      path = ::Rails.root.to_s + "/public" + uri.path
      size = File.size(path) rescue 0
      [resource, size]
    end.to_json.html_safe
  end

  def require_joosy_preloader_for(app_asset, options={})
    preloader_asset = "joosy/preloaders/#{options[:preloader] || 'caching'}"
    force_preloader = options[:force] || false

    if force_preloader
      require_asset preloader_asset
    else
      require_asset Rails.env == 'development' ? app_asset : preloader_asset
    end
  end

  def self.joosy_resources(namespaces=nil)
    predefined = {}
    filtered_resources = Joosy::Rails::Engine.resources
    if namespaces
      namespaces = Array.wrap namespaces
      filtered_resources = filtered_resources.select{|key, _| namespaces.include? key }
    end
    filtered_resources.each do |namespace, resources|
      next unless resources && resources.size > 0
      joosy_namespace = namespace.to_s.camelize.split('::').join('.')
      predefined[joosy_namespace] = resources
    end
    predefined
  end
end
