#= require joosy/core/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  @widget = (tag, options, widget) ->
    unless widget?
      widget  = options
      options = {}

    options.id = Joosy.uid()

    @__renderer.setTimeout 0, =>
      @__renderer.registerWidget($('#'+options.id), widget)

    @tag tag, options