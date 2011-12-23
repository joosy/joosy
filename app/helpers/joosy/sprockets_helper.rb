module Joosy
  module SprocketsHelper
    def extract_sources_and_sizes_from_include_tag(name)
      code = javascript_include_tag name
      resources = code.scan(/(?:href|src)=['"]([^'"]+)['"]/).flatten

      resources.map do |resource|
        size = File.size(Rails.root.join("public", resource)) rescue false
        [resource, size]
      end.to_json.html_safe
    end
  end
end