#= require joosy/core/joosy

Joosy.helpers 'Global', ->
  
  @nl2br = (text) ->
    text.toString().replace(/\n/g, '<br/>')