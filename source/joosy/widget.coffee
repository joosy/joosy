#= require joosy/joosy
#= require joosy/modules/log
#= require joosy/modules/events
#= require joosy/modules/dom
#= require joosy/modules/renderer
#= require joosy/modules/time_manager
#= require joosy/modules/filters

#
# Base class for all Joosy Widgets.
#
# Joosy expects you to perceive your actual application as a tree of widgets. Internally all high-level
# containers like {Joosy.Layout} and {Joosy.Page} are inheriting from Widget. Widget contains logic for:
#
#  * Recursive nesting (widgets can contain widgets, etc.)
#
#  * Loading and Unloading flows (proper initializations, destructions and replacements)
#
#  * Filtering (afterLoad, beforeLoad and the family of paint filters)
#
# During the bootstrap, widgets can take either dependent or independent strategy. Dependent widgets form
# "dependent chains" that will be rendered together (HTML will be injected into DOM atomically). Such chains
# use paint filters of the top elements. Independent widgets on the other hand load on their own behalf and
# use their own paint filters. To understand this better, here is the sample:
#
# Let's say we have 4 widgets A, B, C and D nested into each other:
#
# A is the root widget
# B is nested into A. It does not define itself as an independent and therefore defaults to dependent rendering
# C is nested into B. It defines itself as an independent children
# D is nested into C. It does not define itself as an independent and therefore defaults to dependent rendering
#
# Then total chain of asynchronous callbacks goes with the following scenario.
#
# 1. A collects all the fetches from the whole tree recursively and starts them in parallel.
#
# 2. A runs erase on the previous same-level widget (attribute `@previous`) if one is given.
#
# 3. A runs beforePaint on itself when 2 is done.
#
# 4. A waits for step 3 and all fetches of containers in recursive dependency chain (equal to B) to complete.
#
# 5. A builds resulting HTML using:
#
#   * HTML of dependency chain (B)
#
#   * HTML of independent containers that are ready to be rendered (their own recursive dependency chain is fetched completely).
#
# 5. A forks every independent container that was not rendered (C).
#
# 6. A starts paint on itself and injects HTML into DOM.
#
# 7. C repeats steps 2-7 using itself as a base and D as its own recursive dependency chain
#
# @method .beforeLoad(callback)
#   Initialization hook that runs in the very begining of bootstrap process.
#   Call it multiple times to attach several hooks.
#
# @method .afterLoad(callback)
#   Hook that runs after the section was properly loaded and injected into DOM.
#   Call it multiple times to attach several hooks.
#
# @method .beforeUnload(callback)
#   Hook that finalizes section desctruction.
#   Call it multiple times to attach several hooks.
#
# @method .fetch(callback)
#   Sets the method which will controll the data fetching proccess.
#   @note Given method will be called with `complete` function as parameter. As soon as your
#     preparations are done you should call that function.
#   @example Basic usage
#     @fetch (complete) ->
#       $.get '/rumbas', (@data) => complete()
#
# @method .beforePaint(callback)
#   Sets the method which will controll the painting preparation proccess.
#   This method will be called right ater previous section erase and in parallel with
#     new data fetching so you can use it to initiate preloader.
#   @note Given method will be called with `complete` function as parameter. As soon as your
#     preparations are done you should call that function.
#   @example Sample before painter
#     @beforePaint (complete) ->
#       @$preloader.slideDown -> complete()
#
# @method .paint(callback)
#   Sets the method which will controll the painting proccess.
#   This method will be called after fetching, erasing and beforePaint is complete.
#   It should be used to setup appearance effects of page.
#   @note Given method will be called with `complete` function as parameter. As soon as your
#     preparations are done you should call that function.
#   @example Sample painter
#     @paint (complete) ->
#       @$container.fadeIn -> complete()
#
# @method .erase(callback)
#   Sets the method which will controll the erasing proccess.
#   Use this method to setup hiding effect.
#   @note Given method will be called with `complete` function as parameter. As soon as your
#     preparations are done you should call that function.
#   @note This method will be called _before_ unload routines so in theory you can
#     access page data from that. Think twice if you are doing it right though.
#   @example Sample eraser
#     @erase (complete) ->
#       @$container.fadeOut -> complete()
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @concern Joosy.Modules.DOM
# @concern Joosy.Modules.Renderer
# @include Joosy.Modules.TimeManager
# @extend Joosy.Modules.Filters
#
class Joosy.Widget extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @concern Joosy.Modules.DOM
  @concern Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @extend Joosy.Modules.Filters

  #
  # Extends widgets mapping
  #
  # Pass either widget class or instance as a value. Given lambdas are evaluated.
  #
  # @example
  #   @mapWidgets
  #     '.selector1': Widget1
  #     '.selector2': -> @widget = new Widget2
  #
  @mapWidgets: (map) ->
    unless @::hasOwnProperty "__widgets"
      @::__widgets = Joosy.Module.merge {}, @.__super__.__widgets
    Joosy.Module.merge @::__widgets, map

  #
  # Declares widget as indepent changing the way it behaves during the bootstrap
  #
  @independent: ->
    @::__independent = true

  @registerPlainFilters 'beforeLoad', 'beforeUnload', 'afterLoad', 'afterUnload'

  @registerSequencedFilters 'beforePaint', 'paint', 'erase', 'fetch'

  #
  # @param [Hash] params              Arbitrary parameters
  # @param [Joosy.Layout] previous    Same-level widget to replace
  #
  constructor: (@params, @previous) ->

  #
  # Registeres and runs widget inside specified container
  #
  # @param [DOM] container              jQuery or direct dom node object
  # @param [Joosy.Widget] widget        Class or object of Joosy.Widget to register
  #
  registerWidget: ($container, widget) ->
    if typeof($container) == 'string'
      $container = @__normalizeSelector($container)

    widget = @__normalizeWidget(widget)
    widget.__bootstrapDefault @, $container

    widget

  #
  # Unregisteres and destroys widget
  #
  # @param [Joosy.Widget] widget          Object of Joosy.Widget to unregister
  #
  unregisterWidget: (widget) ->
    widget.__unload()

  #
  # Unloads the previous widget and inject the new one inplace saving
  # the continuity
  #
  replaceWidget: (widget, replacement) ->
    replacement = @__normalizeWidget(replacement)
    replacement.previous = widget

    replacement.__bootstrapDefault @, widget.$container
    replacement

  #
  # @see Joosy.Router.navigate
  #
  navigate: ->
    Joosy.Router?.navigate arguments...

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/widgets
  #
  __renderSection: ->
    'widgets'

  #
  # Collects statically registered widgets to form default nesting map
  #
  __nestingMap: ->
    map = {}

    for selector, widget of @__widgets
      widget = @__normalizeWidget(widget)

      map[selector] =
        instance: widget
        nested: widget.__nestingMap()

    map

  #
  # Shortcut for default bootstrap using statically registered widgets
  #
  # @param [jQuery] $container                 DOM container to inject to
  #
  __bootstrapDefault: (parent, $container) ->
    @__bootstrap parent, @__nestingMap(), $container

  #
  # Bootstraps the section with given nestings at given container
  #
  # @example
  #   nestingMap =
  #     '.page':
  #       instance: page
  #       nested:
  #         '.widget1': {instance: widget1}
  #
  #   layout.__bootstrap nestingMap, Joosy.Application.content()
  #
  # @param [Object] nestingMap              Map of nested sections to bootstrap
  # @param [jQuery] $container              DOM container to inject into
  # @param [boolean] fetch                  Boolean flag used to avoid double fetch during recursion
  #
  __bootstrap: (parent, nestingMap, @$container, fetch=true) ->
    @wait 'section:fetched section:erased', =>
      @__runPaints [], =>
        @__paint parent, nestingMap, @$container

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

    @synchronize (context) =>
      for selector, section of nestingMap
        do (selector, section) ->
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
  __erase: (parent) ->
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
  __paint: (@parent, nestingMap, @$container) ->
    @__nestedSections = []
    @$container.html @__renderDefault?(@data || {})

    for selector, section of nestingMap
      do (selector, section) =>
        $container = @__normalizeSelector(selector)

        if !section.instance.__independent || section.instance.__triggeredEvents?['section:fetched']
          section.instance.__paint @, section.nested, $container
        else
          section.instance.__bootstrap @, section.nested, $container, false

    @__load()

  #
  # Initializes section that was injected into DOM
  #
  __load: ->
    if @parent
      @parent.__nestedSections ||= []
      @parent.__nestedSections.push @

    @__assignElements()
    @__delegateEvents()
    @__runAfterLoads()
    @trigger name: 'loaded', remember: true

  #
  # Deinitializes section that is preparing to be removed from DOM
  #
  __unload: (modifyParent=true) ->
    @__runBeforeUnloads()

    if @__nestedSections
      section.__unload(false) for section in @__nestedSections
      delete @__nestedSections

    @__clearContainer()
    @__clearTime()
    @__destructRenderingStack()
    @__runAfterUnloads()

    if @parent && modifyParent
      @parent.__nestedSections.splice @parent.__nestedSections.indexOf(@), 1

    delete @previous
    delete @parent

  #
  # Normalizes selector and returns jQuery wrap.
  #
  # Selector can be one of:
  #
  #   * $container - gets raw main container
  #   * $elem      - attempts to get values from {Joosy.Modules.DOM} mappings
  #   * .selector  - raw CSS selectors pass as-is
  #
  __normalizeSelector: (selector) ->
    if selector == '$container'
      @$container
    else
      $(@__extractSelector(selector), @$container)

  #
  # Normalizes widget descrpition to its instance.
  #
  # Besides already being instance it can be either class or lambda
  #
  __normalizeWidget: (widget) ->
    if typeof(widget) == 'function' && !Joosy.Module.hasAncestor(widget, Joosy.Widget)
      widget = widget.call(@)

    if Joosy.Module.hasAncestor widget, Joosy.Widget
      widget = new widget

    widget

# AMD wrapper
if define?.amd?
  define 'joosy/widget', -> Joosy.Widget
