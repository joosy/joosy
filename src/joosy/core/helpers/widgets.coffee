#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (element, widget) ->
    uuid    = Joosy.uid()
    params  = id: uuid
    parts   = element.split '.'
    if parts[1]
      params.class = parts.from(1).join ' '

    @tag parts[0], params