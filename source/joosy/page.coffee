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
#   class @RumbaPage extends Joosy.Page
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


  @registerPlainFilters 'beforeLoad', 'afterLoad', 'afterUnload'

  @registerSequencedFilters \

    #
    # @method .beforePaint(container, complete)
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
    'beforePaint',

    #
    # @method .paint(container, complete)
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
    'paint',

    #
    # @method .erase(container, complete)
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
    'erase',

    #
    # @method .fetch(complete)
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
    'fetch'

  @include Joosy.Modules.Page_Scrolling
  @extend  Joosy.Modules.Page_Title

  #
  # Constructor is very destructive (c), it calls bootstrap directly so use with caution.
  #
  # @params [Hash] params             Route params
  # @params [Joosy.Page] previous     Previous page to unload
  #
  constructor: (applicationContainer, @params, @previous) ->
    @__layoutClass = @__layoutClass || (if @__layoutClass != false then window.ApplicationLayout else null)

    unless @halted = !@__runBeforeLoads(@params, @previous)
      @__bootstrap applicationContainer

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

  __newLayoutNeeded: ->
    @__layoutClass? && (!@previous?.layout?.uid? || @previous?.__layoutClass != @__layoutClass)

  __getLayout: (applicationContainer) ->
    switch
      when @__newLayoutNeeded()
        new @__layoutClass applicationContainer, @params
      when @__layoutClass
        @previous.layout
      else
        null

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
    @layout = @__getLayout(applicationContainer)

    if layoutChanged = @__newLayoutNeeded()
      currentHandler  = @layout
      previousHandler = @previous?.layout
      filterParams    = [@layout.container, @]
    else
      currentHandler  = @
      previousHandler = @previous
      filterParams    = if @layout then [@layout.content()] else [applicationContainer]

    @wait "stageClear dataReceived", =>
      currentHandler.__runPaints filterParams, =>

        # Layout HTML
        if layoutChanged && @layout?.__renderDefault?
          @layout.container.html @layout.__renderDefault(@layout.data || {})

        # Page HTML
        @container = @layout?.content() || applicationContainer
        @container.html @__renderDefault(@data || {}) if @__renderDefault?

        # Loading
        @layout.__load() if layoutChanged
        @__load()

    # Clearing stage
    clearStage = =>
      @previous?.layout?.__unload?() if layoutChanged
      @previous?.__unload()
      
      currentHandler.__runBeforePaints filterParams, =>
        @trigger 'stageClear'

    if previousHandler?
      previousHandler.__runErases filterParams, clearStage
    else
      clearStage()

    # Loading data required for new things
    loadPageData = =>
      @data = {}
      @__runFetchs [], =>
        @dataFetched = true
        Joosy.Modules.Log.debugAs @, "Fetch complete"
        @trigger 'dataReceived'

    if layoutChanged
      @layout.data = {}
      @layout.__runFetchs [], =>
        @layout.dataFetched = true
        loadPageData()
    else
      loadPageData()

# AMD wrapper
if define?.amd?
  define 'joosy/page', -> Joosy.Page
