Joosy.Modules.WidgetsManager =
  registerWidget: (container, widget) ->
    @__activeWidgets ||= []

    if Joosy.Module.hasAncestor(widget, Joosy.Widget)
      widget = new widget()

    @__activeWidgets.push widget.__load(@, container)
    return widget

  unregisterWidget: (widget) ->
    widget.__unload()
    delete @__activeWidgets[@__activeWidgets.indexOf(widget)]

  __collectWidgets: ->
    widgets = Object.extended(@widgets || {})
    klass = @
    while klass = klass.constructor.__super__
      widgets.merge(klass.widgets, false)
    widgets

  __setupWidgets: ->
    widgets = @__collectWidgets()

    widgets.each (selector, widget) =>
      if selector == '$container'
        selector = @container
      else
        if r = selector.match(/\$([A-z_]+)/)
          selector = @elements[r[1]]
        selector = $(selector, @container)

      Joosy.Modules.Log.debug "Widget registered at '#{selector.selector}'. Elements: #{selector.length}"

      selector.each (i, elem) =>
        if Joosy.Module.hasAncestor(widget, Joosy.Widget)
          w = new widget
        else
          w = widget.call @, i

        @registerWidget($(elem), w)

  __unloadWidgets: ->
    if @__activeWidgets
      widget?.__unload() for widget in @__activeWidgets