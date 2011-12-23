class @<%= file_name.camelize %>Layout extends ApplicationLayout
  view: JST['<%= app_path %>/templates/layouts/<%= file_name %>']
