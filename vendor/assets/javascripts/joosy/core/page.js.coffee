#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/time_manager
#= require joosy/core/modules/widgets_manager
#= require joosy/core/modules/filters

class Joosy.Page extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  layout: false
  previous: false
  params: false
  source: false
  data: false

  @fetch: (callback) -> @::__fetch = callback
  @scroll: (element, speed=500) -> 
    @::__scrollElement = element
    @::__scrollSpeed = speed

  @before_page_render: (callback) -> @::__before_page_render = callback
  @after_page_render:  (callback) -> @::__after_page_render = callback
  @on_page_render: (callback) -> @::__on_page_render = callback

  @before_layout_render: (callback) -> @::__before_page_render = callback
  @after_layout_render: (callback) -> @::__after_layout_render = callback
  @on_layout_render: (callback) -> @::__on_layout_render = callback
  
  @after_load ->
    if @__scrollElement
      $('html, body').animate({scrollTop: $(@__extractSelector(@__scrollElement)).offset().top}, @__scrollSpeed)

  constructor: (@params, @previous) ->
    @layout ||= ApplicationLayout

    if @__runBeforeLoads(@params, @previous)
      if @previous?.layout not instanceof @layout
        @__renderLayout()
      else
        @__render()

  navigate: (args...) -> Joosy.Router.navigate(args...)

  __load: ->
    @refreshElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads(@params, @previous)

  __unload: ->
    @clearTime()
    @__unloadWidgets()
    @__runAfterUnloads(@params, @previous)

  __render: ->
    @layout = @previous.layout

    @wait "stageClear dataReceived", =>
      @previous?.__unload()

      render = =>
        @swapContainer @layout.content(), @view(@data)
        @container = @layout.content()

        @__load()
        Joosy.Beautifier.go()

        if @__after_page_render?
          @__after_page_render @layout.content()

        return @layout.content()

      if @__on_page_render?
        @__on_page_render @layout.content(), render
      else
        render()

    if @__before_page_render?
      @__before_page_render @layout.content(), =>
        @trigger 'stageClear'
    else
      @trigger 'stageClear'

    if @__fetch?
      @__fetch =>
        @trigger 'dataReceived'
    else
      @trigger 'dataReceived'

  __renderLayout: ->
    @layout = new @layout

    @wait "stageClear dataReceived", =>

      @previous?.layout?.__unload?()
      @previous?.__unload()

      render = =>
        @swapContainer Joosy.Application.content(), @layout.view(@data)
        @swapContainer @layout.content(), @view(@data)
        @container = @layout.content()

        @layout.__load Joosy.Application.content()
        @__load()
        Joosy.Beautifier.go()

        if @__after_layout_render?
          @__after_layout_render Joosy.Application.content()

        return Joosy.Application.content()

      if @__on_layout_render?
        @__on_layout_render Joosy.Application.content(), render
      else
        render()


    if @__before_layout_render?
      @__before_layout_render Joosy.Application.content(), =>
        @trigger 'stageClear'
    else
      @trigger 'stageClear'

    if @__fetch?
      @__fetch =>
        @trigger 'dataReceived'
    else
      @trigger 'dataReceived'