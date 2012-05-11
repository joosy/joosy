#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (element, widget) ->
    uuid    = Joosy.uuid()
    element = document.createElement element
    temp    = document.createElement 'div'

    element.id = uuid

    @onRefresh -> @registerWidget '#'+uuid, widget

    temp.appendChild element
    temp.innerHTML