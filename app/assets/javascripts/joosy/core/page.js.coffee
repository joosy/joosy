#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/time_manager
#= require joosy/core/modules/widgets_manager
#= require joosy/core/modules/filters

class Joosy.Page extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  layout: false
  previous: false
  params: false
  data: false

  @fetch: (callback) ->
    @::__fetch = callback

  @scroll: (element, options={}) ->
    @::__scrollElement = element
    @::__scrollSpeed = options.speed || 500
    @::__scrollMargin = options.margin || 0
    
  @layout: (layoutClass) ->
    @::__layoutClass = layoutClass

  @beforePageRender: (callback) -> @::__beforePageRender = callback
  @afterPageRender:  (callback) -> @::__afterPageRender = callback
  @onPageRender: (callback) -> @::__onPageRender = callback

  @beforeLayoutRender: (callback) -> @::__beforeLayoutRender = callback
  @afterLayoutRender: (callback) -> @::__afterLayoutRender = callback
  @onLayoutRender: (callback) -> @::__onLayoutRender = callback

  constructor: (@params, @previous) ->
    @__layout ||= ApplicationLayout

    if @__runBeforeLoads(@params, @previous)
      if @previous?.__layout != @__layout
        @__bootstrapLayout()
      else
        @__bootstrap()

  navigate: (args...) -> Joosy.Router.navigate(args...)

  __load: ->
    @refreshElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads(@params, @previous)
    if @__scrollElement
      scroll = $(@__extractSelector(@__scrollElement)).offset()?.top + @__scrollMargin
      $('html, body').animate({scrollTop: scroll}, @__scrollSpeed)
      Joosy.Modules.Log.debug "#{@constructor.name}> Scrolling to #{@__extractSelector(@__scrollElement)}"
      
    Joosy.Modules.Log.debug "#{@constructor.name}> Page loaded"

  __unload: ->
    @clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads(@params, @previous)
    delete @previous

  __bootstrap: ->
    @layout = @previous.layout

    @wait "stageClear dataReceived", =>
      @previous?.__unload()

      complete = =>
        @swapContainer @layout.content(), @__renderer(@data)
        @container = @layout.content()

        @__load()
        Joosy.Beautifier.go()

        if @__afterPageRender?
          @__afterPageRender @layout.content()

        @layout.content()

      if @__onPageRender?
        @__onPageRender @layout.content(), complete
      else
        complete()

    if @__beforePageRender?
      @__beforePageRender @layout.content(), =>
        @trigger 'stageClear'
    else
      @trigger 'stageClear'

    if @__fetch?
      @__fetch =>
        @trigger 'dataReceived'
    else
      @trigger 'dataReceived'

  __bootstrapLayout: ->
    @layout = new @__layoutClass

    @wait "stageClear dataReceived", =>
      @previous?.layout?.__unload?()
      @previous?.__unload()

      complete = =>
        @swapContainer Joosy.Application.content(), @layout.__renderer
          yield: =>
            @layout.yield()
        @swapContainer @layout.content(), @__renderer(@data)
        @container = @layout.content()
        
        @layout.__load Joosy.Application.content()
        @__load()
        
        Joosy.Beautifier.go()
        
        if @__afterLayoutRender?
          @__afterLayoutRender Joosy.Application.content()
        
        Joosy.Application.content()

      if @__onLayoutRender?
        @__onLayoutRender Joosy.Application.content(), complete
      else
        complete()

    if @__beforeLayoutRender?
      @__beforeLayoutRender Joosy.Application.content(), =>
        @trigger 'stageClear'
    else
      @trigger 'stageClear'

    if @__fetch?
      @__fetch =>
        @trigger 'dataReceived'
    else
      @trigger 'dataReceived'