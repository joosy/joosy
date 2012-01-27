Joosy.namespace '<%= namespace_name %>', ->

  class @<%= file_name.camelize %>Page extends ApplicationPage
    @layout <%= layout_name.camelize %>Layout
    @view   '<%= file_name %>'
