#= require joosy/core/joosy

Joosy.helpers 'Application', ->
  
  @nl2br = (text) ->
    text.toString().replace /\n/g, '<br/>'
