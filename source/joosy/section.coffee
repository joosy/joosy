class Joosy.Section extends Joosy.Module
  @include Joosy.Modules.Events
  @include Joosy.Modules.DOM
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.Filters

  @independent: ->
    @::__independent = true

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

  constructor: (@params, @previous) ->

  __bootstrap: (nestingMap, $container, fetch=true) ->
    @wait 'section:fetched section:erased', =>
      @__runPaints [], =>
        @__paint nestingMap, $container

    @__erase()
    @__fetch(nestingMap) if fetch

  __fetch: (nestingMap) ->
    @data = {}

    Joosy.synchronize (context) =>
      Object.each nestingMap, (selector, section) ->
        section.instance.__fetch(section.nested)

        if !section.instance.__independent
          context.do (done) ->
            section.instance.wait 'section:fetched', done

      context.do (done) =>
        @__runFetchs [], done

      context.after =>
        @trigger name: 'section:fetched', remember: true

  __erase: ->
    if @previous?
      @previous.__runErases [], =>
        @previous.__unload()

        @__runBeforePaints [], =>
          @trigger name: 'section:erased', remember: true
    else
      @__runBeforePaints [], =>
        @trigger name: 'section:erased', remember: true

  __paint: (nestingMap, @$container) ->
    @$container.html @__renderDefault?()

    Object.each nestingMap, (selector, section) =>
      if selector == '$container'
        $container = @$container
      else
        selector   = @__extractSelector(selector)
        $container = $(selector, @$container)

      if !section.instance.__independent || section.instance.__triggeredEvents?['section:fetched:self']
        section.instance.__paint section.nested, $container
      else
        section.instance.__bootstrap section.nested, $container, false

    @__load()

  __load: ->
    @__assignElements()
    @__delegateEvents()
    @__runAfterLoads @params, @previous

  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__removeMetamorphs()
    @__runAfterUnloads @params, @previous
    delete @previous