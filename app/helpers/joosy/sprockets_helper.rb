module Joosy
  module SprocketsHelper
    def extract_sources_and_sizes_from_include_tag(name)
      code = javascript_include_tag name
      resources = code.scan(/(?:href|src)=['"]([^'"]+)['"]/).flatten

      resources.map do |resource|
        path = ::Rails.root.to_s + "/public" + resource.split('?')[0]
        size = File.size(path) rescue false
        [resource, size]
      end.to_json.html_safe
    end
  end
end