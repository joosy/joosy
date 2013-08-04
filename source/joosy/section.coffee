#= require joosy/joosy
#= require joosy/modules/log
#= require joosy/modules/events
#= require joosy/modules/dom
#= require joosy/modules/renderer
#= require joosy/modules/time_manager
#= require joosy/modules/filters

#
# Basic rendering and filtering mechanics for disposition components.
# Typical disposition components are Page, Layout and Widget.
#
# Flow description:
# 
# Let's say we have 4 containers A, B, C and D nested into each other:
#
# A is the root container
# B is nested into A. It does not define itself as an independent and therefore defaults to dependent rendering
# C is nested into B. It defines itself as an independent children providing template to render in its
#   future container unless it is ready to be rendered
# D is nested into C. It does not define itself as an independent and therefore defaults to dependent rendering
#
# Then total chain of asynchronous callbacks goes with the following scenario.
# 
# 1. A collects all the fetches from the whole tree recursively and starts them in parallel.
# 2. A runs erase on the previous Container (attribute `@previos`) if one is given.
# 3. A runs beforePaint on itself when 2 is done.
# 4. A waits for step 3 and all fetches of containers in recursive dependency chain (B) to complete.
# 5. A builds resulting HTML using:
#   * HTML of dependent containers (B)
#   * HTML of independent containers that are ready to be rendered (their own recursive dependency chain is fetched completely)
# 5. A forks every independent container (C) and forces them to control their events on their own behalf.
# 6. A starts paint on itself and injects HTML into DOM.
# 7. C repeats steps 2-7 using itself as a base
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.DOM
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.TimeManager
# @include Joosy.Modules.Filters
#
class Joosy.Section extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.DOM
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.Filters

  @independent: ->
    @::__independent = true

  @registerPlainFilters \
    #
    # @method .beforeLoad(callback)
    #
    # Initialization hook that runs in the very begining of bootstrap process.
    # Call it multiple times to attach several hooks.
    #
    'beforeLoad',

    #
    # @method .afterLoad(callback)
    #
    # Hook that runs after the section was properly loaded and injected into DOM.
    # Call it multiple times to attach several hooks.
    #
    'afterLoad',

    #
    # @method .beforeUnload(callback)
    #
    # Hook that finalizes section desctruction.
    # Call it multiple times to attach several hooks.
    #
    'afterUnload'

  @registerSequencedFilters \

    #
    # @method .beforePaint(callback)
    #
    # Sets the method which will controll the painting preparation proccess.
    #
    # This method will be called right ater previous section erase and in parallel with
    #   new data fetching so you can use it to initiate preloader.
    #
    # @note Given method will be called with `complete` function as parameter. As soon as your
    #   preparations are done you should call that function.
    #
    # @example Sample before painter
    #   @beforePaint (complete) ->
    #     @$preloader.slideDown -> complete()
    #
    #
    'beforePaint',

    #
    # @method .paint(callback)
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
    #   @paint (complete) ->
    #     @$container.fadeIn -> complete()
    #
    'paint',

    #
    # @method .erase(callback)
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
    #   @erase (complete) ->
    #     @$container.fadeOut -> complete()
    #
    'erase',

    #
    # @method .fetch(callback)
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

  #
  # Bootstraps the section with given nestings at given container
  #
  # @example
  #   nestingMap =
  #     '#page':
  #       instance: page
  #       nested:
  #         '#widget1': {instance: widget1}
  #
  #   layout.__bootstrap nestingMap, Joosy.Application.content()
  #
  # @param [Object] nestingMap              Map of nested sections to bootstrap
  # @param [jQuery] $container              DOM container to inject into
  # @param [boolean] fetch                  Boolean flag used to avoid double fetch during recursion
  #
  __bootstrap: (nestingMap, @$container, fetch=true) ->
    @wait 'section:fetched section:erased', =>
      @__runPaints [], =>
        @__paint nestingMap, @$container

    @__erase()
    @__fetch(nestingMap) if fetch

  #
  # Recursively starts fetching for the whole nested tree. As soon as fetching is done, section
  # triggers rememberable event 'section:fetched'
  #
  # Section can be considered fetched if (and triggers event when):
  #   * Its fetchers are complete
  #   * All the fetchers of all dependent nestings are complete
  #
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

  #
  # Runs erasing chain for the previous section and beforePaints for current
  #
  __erase: ->
    if @previous?
      @previous.__runErases [], =>
        @previous.__unload()

        @__runBeforePaints [], =>
          @trigger name: 'section:erased', remember: true
    else
      @__runBeforePaints [], =>
        @trigger name: 'section:erased', remember: true

  #
  # Builds HTML of section and its dependent nestings and injects it into DOM
  #
  __paint: (nestingMap, @$container) ->
    @$container.html @__renderDefault?(@data || {})

    Object.each nestingMap, (selector, section) =>
      if selector == '$container'
        $container = @$container
      else
        selector   = @__extractSelector(selector)
        $container = $(selector, @$container)

      if !section.instance.__independent || section.instance.__triggeredEvents?['section:fetched']
        section.instance.__paint section.nested, $container
      else
        section.instance.__bootstrap section.nested, $container, false

    @__load()

  #
  # Initializes section that was injected into DOM
  #
  __load: ->
    @__assignElements()
    @__delegateEvents()
    @__runAfterLoads()

  #
  # Deinitializes section that is preparing to be removed from DOM
  #
  __unload: ->
    @__clearContainer()
    @__clearTime()
    @__removeMetamorphs()
    @__runAfterUnloads()
    delete @previous

  #
  # @see Joosy.Router.navigate
  #
  navigate: ->
    Joosy.Router?.navigate arguments...