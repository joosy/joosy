#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/time_manager
#= require joosy/core/modules/widgets_manager
#= require joosy/core/modules/filters

class Joosy.Layout extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  @view 'default'

  @beforePaint: (callback) ->
    @::__beforePaint = callback
  @paint: (callback) ->
    @::__paint = callback
  @erase: (callback) ->
    @::__erase = callback
    
  @fetch: (callback) ->
    @::__fetch = callback

  data: false
  
  constructor: (@params) ->

  navigate: (args...) ->
    Joosy.Router.navigate(args...)

  __renderSection: ->
    'layouts'

  __load: (@container) ->
    @refreshElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

  __unload: ->
    @__clearTime()
    @__unloadWidgets()
    @__runAfterUnloads()

  yield: ->
    @uuid = Joosy.uuid()

  content: ->
    $("##{@uuid}")
