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
end