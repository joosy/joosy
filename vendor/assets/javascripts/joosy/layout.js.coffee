class Joosy.Layout extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  constructor: ->
    @view  ||= JST['app/templates/layouts/default']

  navigate: (args...) -> Joosy.Router.navigate(args...)

  __load: (@container) ->
    @refreshElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

  __unload: ->
    @clearTime()
    @__unloadWidgets()
    @__runAfterUnloads()

  yield: ->
    @uuid = Joosy.uuid()

  content: ->
    $("##{@uuid}")