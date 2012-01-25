Joosy.Modules.WidgetsManager =
  registerWidget: (container, widget) ->
    if Joosy.Module.hasAncestor(widget, Joosy.Widget)
      widget = new widget()

    @__activeWidgets ||= []
    @__activeWidgets.push widget.__load(this, container)

    return widget

  unregisterWidget: (widget) ->
    widget.__unload()

    @__activeWidgets.splice(@__activeWidgets.indexOf(widget))

  __collectWidgets: ->
    widgets = Object.extended(@widgets || {})

    klass = this
    while klass = klass.constructor.__super__
      widgets.merge(klass.widgets, false)

    widgets

  __setupWidgets: ->
    widgets = @__collectWidgets()
    registereds = Object.extended()

    widgets.each (selector, widget) =>  
      if selector == '$container'
        activeSelector = @container
      else
        if r = selector.match(/\$([A-z_]+)/)
          selector = @elements[r[1]]
        activeSelector = $(selector, @container)

      registereds[selector] = Object.extended()

      activeSelector.each (i, elem) =>
        if Joosy.Module.hasAncestor(widget, Joosy.Widget)
          w = new widget
        else
          w = widget.call this, i

        registereds[selector][w.constructor.name] ||= 0
        registereds[selector][w.constructor.name] += 1

        @registerWidget($(elem), w)

    registereds.each (selector, value) =>
      value.each (widget, count) =>
        Joosy.Modules.Log.debug "Widget #{widget} registered at '#{selector}'. Elements: #{count}"

  __unloadWidgets: ->
    if @__activeWidgets
      for widget in @__activeWidgets
        widget.__unload()