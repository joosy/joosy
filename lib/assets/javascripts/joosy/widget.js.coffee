class Joosy.Widget extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Filters

  __render: false

  @render: (callback) ->
    @::__render = callback

  setInterval: (args...) ->
    @parent.setInterval(args...)

  setTimeout: (args...) ->
    @parent.setTimeout(args...)

  navigate: (args...) -> Joosy.Router.navigate(args...)

  __load: (@parent, @container) ->
    @__render?()
    @refreshElements()
    @__delegateEvents()
    @__runAfterLoads()
    return @

  __unload: ->
    @__runAfterUnloads()