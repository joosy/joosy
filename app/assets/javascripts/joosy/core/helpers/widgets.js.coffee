#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (element, widget) ->
    uuid    = Joosy.uuid()
    element = @tag element, id: uuid

    @onRefresh -> @registerWidget '#'+uuid, widget

    element