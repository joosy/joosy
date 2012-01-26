Joosy.namespace '<%= namespace_name %>', ->

  class @<%= file_name.camelize %>Page extends ApplicationPage
    @layout <%= layout_name.camelize %>Layout
    @view   'pages/<%= namespace_path %>/<%= file_name %>'
