#= require joosy/joosy
#= require joosy/section
#= require joosy/modules/widgets_manager

#
# Base class for all Joosy Widgets.
#
# @example Sample widget
#   class @FooWidget extends Joosy.Widget
#     @view 'foo'
#
# @include Joosy.Modules.WidgetsManager
#
class Joosy.Widget extends Joosy.Section
  @include Joosy.Modules.WidgetsManager

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/widgets
  #
  __renderSection: ->
    'widgets'

  #
  # Widget bootstrap proccess
  #
  #   * Rendering (if required)
  #   * {Joosy.Modules.DOM.__assignElements}
  #   * {Joosy.Modules.DOM.__delegateEvents}
  #
  # @param [Joosy.Page, Joosy.Layout]     Page or Layout to attach to
  # @param [jQuery] container             Container to attach to
  #
  __load: (@parent, @$container, render=true) ->
    @__runBeforeLoads()
    if render && @__renderDefault
      @$container.html @__renderDefault(@data || {})
    @__assignElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

    this

  #
  # Layout destruction proccess.
  #
  #   * {Joosy.Modules.DOM.__clearContainer}
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads()

# AMD wrapper
if define?.amd?
  define 'joosy/widget', -> Joosy.Widget