#= require joosy/joosy
#= require joosy/layout
#= require joosy/widget
#= require joosy/modules/log
#= require joosy/modules/events
#= require joosy/modules/container
#= require joosy/modules/renderer
#= require joosy/modules/time_manager
#= require joosy/modules/widgets_manager
#= require joosy/modules/filters
#= require joosy/modules/page/scrolling
#= require joosy/modules/page/title

#
# Base class for all of your Joosy Pages.
# @see http://guides.joosy.ws/guides/blog/layouts-pages-and-routing.html
#
# @example Sample application page
#   class @RumbaPage extends Joosy.Layout
#     @view 'rumba'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.Container
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.TimeManager
# @include Joosy.Modules.WidgetsManager
# @include Joosy.Modules.Filters
#
class Joosy.Page extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters
  @include Joosy.Modules.Page_Scrolling
  @extend  Joosy.Modules.Page_Title

  halted: false

  #
  # Default layout is no layout.
  #
  layout: false

  #
  # Previous page.
  #
  previous: false

  #
  # Route params.
  #
  params: false

  #
  # Prefetched page data.
  #
  data: false
  dataFetched: false

  #
  # Sets layout for current page
  #
  # @param [Class] layoutClass      Layout to use
  #
  @layout: (layoutClass) ->
    @::__layoutClass = layoutClass

  #
  # Sets the method which will controll the painting preparation proccess.
  #
  # This method will be called right ater previous page {Joosy.Page.erase} and in parallel with
  #   page data fetching so you can use it to initiate preloader.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @example Sample before painter
  #   @beforePaint (container, complete) ->
  #     if !@data # checks if parallel fetching finished
  #       $('preloader').slideDown -> complete()
  #
  #
  @beforePaint: (callback) ->
    @::__beforePaint = callback

  #
  # Sets the method which will controll the painting proccess.
  #
  # This method will be called after fetching, erasing and beforePaint is complete.
  # It should be used to setup appearance effects of page.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @example Sample painter
  #   @paint (container, complete) ->
  #     @container.fadeIn -> complete()
  #
  @paint: (callback) ->
    @::__paint = callback

  @afterPaint: (callback) ->
    @::__afterPaint = callback

  #
  # Sets the method which will controll the erasing proccess.
  #
  # Use this method to setup hiding effect.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @note This method will be caled _before_ unload routines so in theory you can
  #   access page data from that. Think twice if you are doing it right though.
  #
  # @example Sample eraser
  #   @erase (container, complete) ->
  #     @container.fadeOut -> complete()
  #
  @erase: (callback) ->
    @::__erase = callback

  #
  # Sets the method which will controll the data fetching proccess.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @example Basic usage
  #   @fetch (complete) ->
  #     $.get '/rumbas', (@data) => complete()
  #
  @fetch: (callback) ->
    @::__fetch = (complete) ->
      @data = {}
      callback.call this, =>
        @dataFetched = true
        complete()

  #
  # Sets the several separate methods that will fetch data in parallel.
  #
  # @note This will work through {Joosy.Modules.Events.synchronize}
  #
  # @example Basic usage
  #   @fetchSynchronized (context) ->
  #     context.do (done) ->
  #       $.get '/rumbas', (data) =>
  #         @data.rumbas = data
  #         done()
  #
  #     context.do (done) ->
  #       $.get '/kutuzkas', (data) =>
  #         @data.kutuzkas = data
  #         done()
  #
  @fetchSynchronized: (callback) ->
    @::__fetch = (complete) ->
      @synchronize (context) ->
        context.after -> complete()
        callback.call(this, context)

  #
  # Constructor is very destructive (c), it calls bootstrap directly so use with caution.
  #
  # @params [Hash] params             Route params
  # @params [Joosy.Page] previous     Previous page to unload
  #
  constructor: (applicationContainer, @params, @previous) ->
    @__layoutClass ||= ApplicationLayout

    unless @halted = !@__runBeforeLoads(@params, @previous)
      if !@previous?.layout?.uid? || @previous?.__layoutClass != @__layoutClass
        @__bootstrapLayout(applicationContainer)
      else
        @__bootstrap(applicationContainer)

  #
  # @see Joosy.Router.navigate
  #
  navigate: ->
    Joosy.Router?.navigate arguments...

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/pages
  #
  __renderSection: ->
    'pages'

  #
  # Page bootstrap proccess
  #
  #   * {Joosy.Modules.Container.__assignElements}
  #   * {Joosy.Modules.Container.__delegateEvents}
  #   * {Joosy.Modules.WidgetsManager.__setupWidgets}
  #   * Scrolling
  #
  __load: ->
    @__assignElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads @params, @previous
    @__performScrolling() if @__scrollElement
    @trigger 'loaded'

    Joosy.Modules.Log.debugAs @, "Page loaded"

  #
  # Page destruction proccess.
  #
  #   * {Joosy.Modules.Container.__clearContainer}
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.WidgetsManager.__unloadWidgets}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads @params, @previous
    delete @previous

  #
  # Proxies callback through possible async wrapper.
  #
  # If wrapper is defined, it will be called with given callback as one of parameters.
  # If wrapper is not defined callback will be called directly.
  #
  # @note Magic People Voodoo People
  #
  # @param [Object] entity        Object possibly containing wrapper method
  # @param [String] receiver      String name of wrapper method inside entity
  # @param [Hash] params          Params to send to wrapper, callback will be
  #   attached as the last of them.
  # @param [Function] callback    Callback to run
  #
  __callSyncedThrough: (entity, receiver, params, callback) ->
    if entity?[receiver]?
      entity[receiver].apply entity, params.clone().add(callback)
    else
      callback()

  #
  # The single page (without layout reloading) bootstrap logic
  #
  # @example Hacky boot sequence description
  #   previous::erase  \
  #   previous::unload  \
  #   beforePaint        \
  #                       > paint
  #   fetch             /
  #
  __bootstrap: (applicationContainer) ->
    Joosy.Modules.Log.debugAs @, "Boostraping page"
    @layout = @previous.layout

    callbacksParams = [@layout.content()]

    if @__scrollElement && @__scrollSpeed != 0
      @__fixHeight()

    @wait "stageClear dataReceived", =>
      @previous?.__afterPaint?(callbacksParams)
      @__callSyncedThrough this, '__paint', callbacksParams, =>
        # Page HTML
        @container = @layout.content()
        @container.html @__renderDefault(@data || {}) if @__renderDefault?

        # Loading
        @__load()

    @__callSyncedThrough @previous, '__erase', callbacksParams, =>
      @previous?.__unload()
      @__callSyncedThrough @, '__beforePaint', callbacksParams, =>
        @trigger 'stageClear'

    @__callSyncedThrough @, '__fetch', [], =>
      Joosy.Modules.Log.debugAs @, "Fetch complete"
      @trigger 'dataReceived'

  #
  # The page+layout bootstrap logic
  #
  # @example Hacky boot sequence description
  #   previous::erase  \
  #   previous::unload  \
  #   beforePaint        \
  #                       > paint
  #   fetch             /
  #
  __bootstrapLayout: (applicationContainer) ->
    Joosy.Modules.Log.debugAs @, "Boostraping page with layout"
    @layout = new @__layoutClass(applicationContainer, @params)

    callbacksParams = [@layout.container, this]

    if @__scrollElement && @__scrollSpeed != 0
      @__fixHeight()

    @wait "stageClear dataReceived", =>
      @__callSyncedThrough @layout, '__paint', callbacksParams, =>
        # Layout HTML
        if @layout.__renderDefault?
          @layout.container.html @layout.__renderDefault(@layout.data || {})

        # Page HTML
        @container = @layout.content()
        @container.html @__renderDefault(@data || {}) if @__renderDefault?

        # Loading
        @layout.__load()
        @__load()

    @__callSyncedThrough @previous?.layout, '__erase', callbacksParams, =>
      @previous?.layout?.__unload?()
      @previous?.__unload()
      @__callSyncedThrough @layout, '__beforePaint', callbacksParams, =>
        @trigger 'stageClear'

    @__callSyncedThrough @layout, '__fetch', [], =>
      @__callSyncedThrough @, '__fetch', [], =>
        Joosy.Modules.Log.debugAs @, "Fetch complete"
        @trigger 'dataReceived'

# AMD wrapper
if define?.amd?
  define 'joosy/page', -> Joosy.Page