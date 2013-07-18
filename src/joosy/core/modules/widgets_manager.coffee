#= require joosy/core/joosy

#
# Widgets management routines
#
# @mixin
#
Joosy.Modules.WidgetsManager =

  included: ->
    @mapWidgets = (map) ->
      unless @::hasOwnProperty "__widgets"
        @::__widgets = Object.clone(@.__super__.__widgets) || {}
      Object.merge @::__widgets, map

  #
  # Registeres and runs widget inside specified container
  #
  # @param [DOM] container              jQuery or direct dom node object
  # @param [Joosy.Widget] widget        Class or object of Joosy.Widget to register
  #
  registerWidget: (container, widget) ->
    if Joosy.Module.hasAncestor widget, Joosy.Widget
      widget = new widget()

    if Object.isFunction(widget)
      widget = widget()

    @__activeWidgets ||= []
    @__activeWidgets.push widget.__load(@, $(container))

    widget

  #
  # Unregisteres and destroys widget
  #
  # @param [Joosy.Widget] widget          Object of Joosy.Widget to unregister
  #
  unregisterWidget: (widget) ->
    widget.__unload()

    @__activeWidgets.splice @__activeWidgets.indexOf(widget), 1

  #
  # Intialize all widgets for current object
  #
  __setupWidgets: ->
    return unless @__widgets

    registered = Object.extended()

    Object.each @__widgets, (selector, widget) =>
      if selector == '$container'
        activeSelector = @container
      else
        selector = @__extractSelector(selector) if @__extractSelector?
        activeSelector = $(selector, @container)

      registered[selector] = Object.extended()

      activeSelector.each (index, elem) =>
        if Joosy.Module.hasAncestor widget, Joosy.Widget
          instance = new widget
        else
          instance = widget.call this, index

        registered[selector][Joosy.Module.__className instance] ||= 0
        registered[selector][Joosy.Module.__className instance]  += 1

        @registerWidget $(elem), instance

    @__widgets = {}

    registered.each (selector, value) =>
      value.each (widget, count) =>
        Joosy.Modules.Log.debugAs @, "Widget #{widget} registered at '#{selector}'. Elements: #{count}"

  #
  # Unregister all widgets for current object
  #
  __unloadWidgets: ->
    if @__activeWidgets
      for widget in @__activeWidgets
        widget.__unload()
