#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (tag, options, widget) ->
    declaration = {}

    unless widget?
      widget  = options
      options = {}

    options.id = Joosy.uid()
    declaration["#{options.id}"] = widget

    @__owner.constructor.mapWidgets declaration
    @tag tag, options