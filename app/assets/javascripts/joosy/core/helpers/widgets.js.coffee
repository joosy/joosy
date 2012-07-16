#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (element, widget) ->
    uuid    = Joosy.uuid()
    params  = id: uuid
    parts   = element.split '.'
    if parts[1]
      params.class = parts.from(1).join ' '

    element = @tag parts[0], params

    @onRefresh -> @registerWidget '#'+uuid, widget

    element