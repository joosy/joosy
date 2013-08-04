#= require joosy/joosy
#= require joosy/section
#= require joosy/widget
#= require joosy/modules/widgets_manager
#= require joosy/helpers/view

#
# Base class for all Joosy Layouts.
#
# @example Sample application layout
#   class @ApplicationLayout extends Joosy.Layout
#     @view 'application'
#
# @include Joosy.Modules.WidgetsManager
#
class Joosy.Layout extends Joosy.Section
  @include Joosy.Modules.WidgetsManager

  @helper 'page'

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/layouts
  #
  __renderSection: ->
    'layouts'

  __nestingMap: (page) ->
    map = {}
    map["##{@uid}"] =
      instance: page
      nested: page.__nestingMap()

    map

  __bootstrapDefault: (page, applicationContainer) ->
    @__bootstrap @__nestingMap(page), applicationContainer

  #
  # @param [Hash] params              List of route params
  #
  constructor: (@params, @previous) ->
    @uid = Joosy.uid()

  #
  # Layout bootstrap proccess.
  #
  #   * {Joosy.Modules.DOM.__assignElements}
  #   * {Joosy.Modules.DOM.__delegateEvents}
  #   * {Joosy.Modules.WidgetsManager.__setupWidgets}
  #
  __load: ->
    @__assignElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

  #
  # Layout destruction proccess.
  #
  #   * {Joosy.Modules.DOM.__clearContainer}
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.WidgetsManager.__unloadWidgets}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads()

  #
  # Helpers that outputs container for the page
  #
  page: (tag, options={}) ->
    options.id = @uid
    Joosy.Helpers.Application.tag tag, options

  #
  # Gets layout element.
  #
  # @return [jQuery]
  #
  content: ->
    $("##{@uid}")

# AMD wrapper
if define?.amd?
  define 'joosy/layout', -> Joosy.Layout
