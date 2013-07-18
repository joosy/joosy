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

    @__owner.setTimeout 0, =>
      @__owner.registerWidget($('#'+options.id), widget)

    @tag tag, options