<%= dependencies %>
#
#= require joosy
#
#= require_tree ./
#= require_self

$ ->
  Joosy.Application.initialize 'body',
    router:
      html5: <%= enableHTML5 %><% if (templaterPrefix && templaterPrefix.length > 0) { %>
    templater:
      prefix: '<%= templaterPrefix %>'<% } %>