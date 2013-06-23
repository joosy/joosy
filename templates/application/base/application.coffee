<%= dependencies %>
#
#= require joosy
#
#= require_tree ./
#= require_self

$ ->
  Joosy.Application.initialize '<%= application %>', 'body'