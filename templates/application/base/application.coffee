#= require jquery/jquery.js
#= require jquery-form/jquery.form.js
#= require sugar/release/sugar-full.min.js
#
#= require joosy
#
#= require_tree ./
#= require_self

$ ->
  Joosy.Application.initialize '<%= application %>', 'body'