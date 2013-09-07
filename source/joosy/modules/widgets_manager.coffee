#= require joosy/joosy

#
# Widgets management routines
#
# @mixin
#
Joosy.Modules.WidgetsManager =

  included: ->
    @mapWidgets = (map) ->
      unless @::hasOwnProperty "__widgets"
        @::__widgets = Joosy.Module.merge {}, @.__super__.widgets
      Joosy.Module.merge @::__widgets, map

  #
  # Registeres and runs widget inside specified container
  #
  # @param [DOM] container              jQuery or direct dom node object
  # @param [Joosy.Widget] widget        Class or object of Joosy.Widget to register
  #
  registerWidget: (container, widget) ->
    if Joosy.Module.hasAncestor widget, Joosy.Widget
      widget = new widget()

    if typeof(widget) == 'function'
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

    registered = {}

    for selector, widget of @__widgets
      if selector == '$container'
        activeSelector = @$container
      else
        selector = @__extractSelector(selector) if @__extractSelector?
        activeSelector = $(selector, @$container)

      registered[selector] = {}

      activeSelector.each (index, elem) =>
        if Joosy.Module.hasAncestor widget, Joosy.Widget
          instance = new widget
        else
          instance = widget.call this, index

        if Joosy.debug()
          registered[selector][Joosy.Module.__className instance] ||= 0
          registered[selector][Joosy.Module.__className instance]  += 1

        @registerWidget $(elem), instance

    @__widgets = {}

    if Joosy.debug()
      for selector, value of registered
        for widget, count of value
          Joosy.Modules.Log.debugAs @, "Widget #{widget} registered at '#{selector}'. Elements: #{count}"

  #
  # Unregister all widgets for current object
  #
  __unloadWidgets: ->
    if @__activeWidgets
      for widget in @__activeWidgets
        widget.__unload()

# AMD wrapper
if define?.amd?
  define 'joosy/modules/widgets_manager', -> Joosy.Modules.WidgetsManager