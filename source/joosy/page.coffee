#= require joosy/joosy
#= require joosy/section
#= require joosy/layout
#= require joosy/widget
#= require joosy/modules/widgets_manager
#= require joosy/modules/page/scrolling
#= require joosy/modules/page/title

#
# Base class for Joosy Pages.
#
# @example Sample application page
#   class @RumbaPage extends Joosy.Page
#     @view 'rumba'
#
# @include Joosy.Modules.WidgetsManager
#
class Joosy.Page extends Joosy.Section
  @include Joosy.Modules.WidgetsManager

  #
  # Sets layout for current page
  #
  # @param [Class] layoutClass      Layout to use
  #
  @layout: (layoutClass) ->
    @::__layoutClass = layoutClass

  @include Joosy.Modules.Page_Scrolling
  @extend  Joosy.Modules.Page_Title

  #
  # This is required by {Joosy.Modules.Renderer}
  # Sets the base template dir to app_name/templates/pages
  #
  __renderSection: ->
    'pages'

  __nestingMap: ->
    {}

  __bootstrapDefault: (applicationContainer) ->
    @__bootstrap @__nestingMap(), @layout?.content() || applicationContainer

  #
  # @params [Hash] params             Route params
  # @params [Joosy.Page] previous     Previous page to unload
  #
  constructor: (@params, @previous) ->
    @layoutShouldChange = @previous?.__layoutClass != @__layoutClass

    @halted = !@__runBeforeLoads(@params, @previous)
    @layout = switch
      when @layoutShouldChange && @__layoutClass
        new @__layoutClass(params, @previous?.layout)
      when !@layoutShouldChange
        @previous?.layout

    # If the page has no layout defined while the previous had one
    # we should declare ourselves as a relpacement to the layout, not the page
    @previous = @previous.layout if @layoutShouldChange && !@layout

  #
  # Page bootstrap proccess
  #
  #   * {Joosy.Modules.DOM.__assignElements}
  #   * {Joosy.Modules.DOM.__delegateEvents}
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
  #   * {Joosy.Modules.DOM.__clearContainer}
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

# AMD wrapper
if define?.amd?
  define 'joosy/page', -> Joosy.Page
