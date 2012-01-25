#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/filters

class Joosy.Widget extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.Filters

  __renderer: false

  @render: (template) ->
    if Object.isString(template)
      @::__renderer = =>
        @container.html @render(template)
    else
      @::__renderer = template

  setInterval: (args...) ->
    @parent.setInterval(args...)

  setTimeout: (args...) ->
    @parent.setTimeout(args...)

  navigate: (args...) ->
    Joosy.Router.navigate(args...)

  __load: (@parent, @container) ->
    @__renderer?()
    @refreshElements()
    @__delegateEvents()
    @__runAfterLoads()

    this

  __unload: ->
    @__removeMetamorphs()
    @__runAfterUnloads()