Joosy.namespace '<%= namespace_name %>', ->

  class @<%= file_name.camelize %>Page extends ApplicationPage
    @layout ApplicationLayout
    @view   '<%= file_name %>'
