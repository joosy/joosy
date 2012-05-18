#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/filters

#
# Base class for all of your Joosy Layouts.
#
# @todo Add link to the 5th chapter of guides here.
#
# @example Sample widget
#   class @FooWidget extends Joosy.Widget
#     @view 'foo'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.Container
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.Filters
# @include Joosy.Modules.TimeManager
#
class Joosy.Widget extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.Filters
  @include Joosy.Modules.TimeManager

  #
  # By default widget will not render on load
  #
  __renderer: false

  #
  # Initial data that will be passed to view on load
  # False (and not {}) by default to have a chance to check if data was loaded
  #
  data: false

  #
  # Proxy to Joosy.Router.navigate
  #
  navigate: (args...) ->
    Joosy.Router.navigate args...

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
  #   * {Joosy.Modules.Container.refreshElements}
  #   * {Joosy.Modules.Container.__delegateEvents}
  #
  # @param [Joosy.Page, Joosy.Layout]     Page or Layout to attach to
  # @param [jQuery] container             Container to attach to
  #
  __load: (@parent, @container, render=true) ->
    if render && @__renderer
      @swapContainer @container, @__renderer(@data || {})
    @refreshElements()
    @__delegateEvents()
    @__runAfterLoads()

    this

  #
  # Layout destruction proccess.
  #
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearTime()
    @__removeMetamorphs()
    @__runAfterUnloads()
