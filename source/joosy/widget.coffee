#= require joosy/joosy
#= require joosy/modules/log
#= require joosy/modules/events
#= require joosy/modules/dom
#= require joosy/modules/renderer
#= require joosy/modules/filters
#= require joosy/modules/time_manager
#= require joosy/modules/widgets_manager

#
# Base class for all of your Joosy Layouts.
#
# @example Sample widget
#   class @FooWidget extends Joosy.Widget
#     @view 'foo'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.DOM
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.Filters
# @include Joosy.Modules.TimeManager
#
class Joosy.Widget extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.DOM
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.Filters
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager

  @registerPlainFilters 'beforeLoad', 'afterLoad', 'afterUnload'

  #
  # By default widget will not render on load
  #
  __renderDefault: false

  #
  # Initial data that will be passed to view on load
  # False (and not {}) by default to have a chance to check if data was loaded
  #
  data: false

  #
  # Proxy to Joosy.Router.navigate
  #
  navigate: ->
    Joosy.Router?.navigate arguments...

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
  __load: (@parent, @container, render=true) ->
    @__runBeforeLoads()
    if render && @__renderDefault
      @container.html @__renderDefault(@data || {})
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