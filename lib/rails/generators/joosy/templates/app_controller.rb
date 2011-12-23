<% module_namespacing do -%>
class <%= class_name %>Controller < ApplicationController
  helper 'joosy/sprockets'

  def index
    render nothing: true, layout: '<%= file_path %>'
  end
end
<% end -%>