#= require joosy/core/joosy
#= require joosy/core/modules/module
#= require joosy/core/modules/log
#= require joosy/core/modules/events
#= require joosy/core/modules/container
#= require joosy/core/modules/renderer
#= require joosy/core/modules/time_manager
#= require joosy/core/modules/widgets_manager
#= require joosy/core/modules/filters

#
# Base class for all of your Joosy Layouts.
# @see http://guides.joosy.ws/guides/layouts-pages-and-routing.html
#
# @example Sample application layout
#   class @ApplicationLayout extends Joosy.Layout
#     @view 'application'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
# @include Joosy.Modules.Container
# @include Joosy.Modules.Renderer
# @include Joosy.Modules.TimeManager
# @include Joosy.Modules.WidgetsManager
# @include Joosy.Modules.Filters
#
class Joosy.Layout extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  @include Joosy.Modules.Container
  @include Joosy.Modules.Renderer
  @include Joosy.Modules.TimeManager
  @include Joosy.Modules.WidgetsManager
  @include Joosy.Modules.Filters

  @view 'default'

  #
  # Sets the method which will controll the painting preparation proccess.
  #
  # This method will be called right ater previous layout {Joosy.Layout.erase} and in parallel with
  #   layout data fetching so you can use it to initiate preloader.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @example Sample before painter
  #   @beforePaint (complete) ->
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
  # It should be used to setup appearance effects of layout.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @example Sample painter
  #   @paint (complete) ->
  #     @container.fadeIn -> complete()
  #
  @paint: (callback) ->
    @::__paint = callback

  #
  # Sets the method which will controll the erasing proccess.
  #
  # Use this method to setup hiding effect.
  #
  # @note Given method will be called with `complete` function as parameter. As soon as your
  #   preparations are done you should call that function.
  #
  # @note This method will be caled _before_ unload routines so in theory you can
  #   access layout data from that. Think twice if you are doing it right though.
  #
  # @example Sample eraser
  #   @erase (complete) ->
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
  # @note You are strongly encouraged to NOT fetch anything with Layout!
  #   Use {Joosy.Page.fetch}
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
  # Prefetched page data.
  #
  data: false
  dataFetched: false

  #
  # @param [Hash] params              List of route params
  #
  constructor: (@params) ->

  #
  # @see Joosy.Router.navigate
  #
  navigate: (args...) ->
    Joosy.Router.navigate(args...)

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/layouts
  #
  __renderSection: ->
    'layouts'

  #
  # Layout bootstrap proccess.
  #
  #   * {Joosy.Modules.Container.refreshElements}
  #   * {Joosy.Modules.Container.__delegateEvents}
  #   * {Joosy.Modules.WidgetsManager.__setupWidgets}
  #
  __load: (@container) ->
    @refreshElements()
    @__delegateEvents()
    @__setupWidgets()
    @__runAfterLoads()

  #
  # Layout destruction proccess.
  #
  #   * {Joosy.Modules.TimeManager.__clearTime}
  #   * {Joosy.Modules.WidgetsManager.__unloadWidgets}
  #   * {Joosy.Modules.Renderer.__removeMetamorphs}
  #
  __unload: ->
    @__clearTime()
    @__unloadWidgets()
    @__removeMetamorphs()
    @__runAfterUnloads()

  #
  # @todo Rename this shit already. We are not going to release having function that marks
  #   element with UUID called `yield`.
  #
  yield: ->
    @uuid = Joosy.uuid()

  #
  # Gets layout element.
  #
  # @return [jQuery]
  #
  content: ->
    $("##{@uuid}")
