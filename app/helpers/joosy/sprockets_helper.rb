module Joosy
  module SprocketsHelper
    def extract_sources_and_sizes_from_include_tag(resource)
      resource = javascript_include_tag resource
      resource = resource.scan(/(href|src)=['"]([^'"]+)['"]/).map { |x| x[1].gsub('.hamljs', '') }

      resource.map do |x|
        size = File.size(Rails.root.to_s + "/public" + x) rescue false
        [x, size]
      end
    end
  end
end