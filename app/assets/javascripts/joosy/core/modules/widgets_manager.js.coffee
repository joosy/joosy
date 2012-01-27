Joosy.Modules.WidgetsManager =
  registerWidget: (container, widget) ->
    if Joosy.Module.hasAncestor(widget, Joosy.Widget)
      widget = new widget()

    @__activeWidgets ||= []
    @__activeWidgets.push widget.__load(this, $(container))

    widget

  unregisterWidget: (widget) ->
    widget.__unload()

    @__activeWidgets.splice(@__activeWidgets.indexOf(widget), 1)

  __collectWidgets: ->
    widgets = Object.extended(@widgets || {})

    klass = this
    while klass = klass.constructor.__super__
      widgets.merge(klass.widgets, false)

    widgets

  __setupWidgets: ->
    widgets    = @__collectWidgets()
    registered = Object.extended()

    widgets.each (selector, widget) =>
      if selector == '$container'
        activeSelector = @container
      else
        if r = selector.match(/\$([A-z_]+)/)
          selector = @elements[r[1]]

        activeSelector = $(selector, @container)

      registered[selector] = Object.extended()

      activeSelector.each (index, elem) =>
        if Joosy.Module.hasAncestor(widget, Joosy.Widget)
          instance = new widget
        else
          instance = widget.call this, index

        registered[selector][Joosy.Module.__className__ instance] ||= 0
        registered[selector][Joosy.Module.__className__ instance]  += 1

        @registerWidget($(elem), instance)

    registered.each (selector, value) =>
      value.each (widget, count) =>
        Joosy.Modules.Log.debugAs @, "Widget #{widget} registered at '#{selector}'. Elements: #{count}"

  __unloadWidgets: ->
    if @__activeWidgets
      for widget in @__activeWidgets
        widget.__unload()