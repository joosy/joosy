Joosy.namespace '<%= layout_name.camelize %>', ->

  class @<%= file_name.camelize %>Page extends ApplicationPage
    layout: <%= layout_name.camelize %>Layout
    view: JST['<%= app_path %>/templates/pages/<%= layout_name %>/<%= file_name %>']
