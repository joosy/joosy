#= require joosy/joosy

#
# Widgets manipulation
#
Joosy.helpers 'Application', ->

  #
  # Injects widget
  #
  # @param [String] tag             Tag name to use a widget container
  # @param [Object] options         Tag attributes
  # @param [Joosy.Widget] widget    Class or instance of {Joosy.Widget} to register
  # @param [Function] widget        Function returning class or instance of {Joosy.Widget}
  #
  # @note Widget instance will be generated on the next asynchronous tick
  #   so make sure to append resulting string to DOM synchronously
  #
  @widget = (tag, options, widget) ->
    unless widget?
      widget  = options
      options = {}

    options.id = Joosy.uid()

    @__renderer.setTimeout 0, =>
      @__renderer.registerWidget($('#'+options.id), widget)

    @tag tag, options