#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/filters

#
# Base Widget class
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
  # Proxy to Joosy.Router#navigate
  #
  navigate: (args...) ->
    Joosy.Router.navigate args...

  #
  # This is required by Joosy.Modules.Renderer
  # Sets the base template dit to app_name/templates/widgets
  #
  __renderSection: ->
    'widgets'

  #
  # The bootstrap mechanic
  #
  # @param [Joosy.Page] parent          Page to attach to
  # @param [Joosy.Layout] parent        Layout to attach to
  # @param [jQuery] container           jQuery element with container to attach to
  #
  __load: (@parent, @container) ->
    if @__renderer
      @container.html @__renderer(@data || {})
    @refreshElements()
    @__delegateEvents()
    @__runAfterLoads()

    this

  #
  # Unload mechanic
  #
  __unload: ->
    @__clearTime()
    @__removeMetamorphs()
    @__runAfterUnloads()
