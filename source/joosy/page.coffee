#= require joosy/joosy
#= require joosy/widget
#= require joosy/layout
#= require joosy/modules/page/scrolling
#= require joosy/modules/page/title

#
# Base class for Joosy Pages.
#
# @example Sample application page
#   class @RumbaPage extends Joosy.Page
#     @view 'rumba'
#
# @include Joosy.Modules.Page.Scrolling
# @extend  Joosy.Modules.Page.Title
#
class Joosy.Page extends Joosy.Widget
  #
  # Sets layout for current page
  #
  # @param [Class] layoutClass      Layout to use
  #
  @layout: (layoutClass) ->
    @::__layoutClass = layoutClass

  @concern Joosy.Modules.Page.Scrolling
  @extend  Joosy.Modules.Page.Title

  #
  # @param [Hash] params             Route params
  # @param [Joosy.Page] previous     Previous page to unload
  #
  constructor: (@params, @previous, options={}) ->
    @layoutShouldChange = options.forceLayout || @previous?.__layoutClass != @__layoutClass

    @halted = !@__confirmBeforeLoads()
    @layout = switch
      when @layoutShouldChange && @__layoutClass
        new @__layoutClass(@params, @previous?.layout)
      when !@layoutShouldChange
        @previous?.layout

    # If the page has no layout defined while the previous had one
    # we should declare ourselves as a relpacement to the layout, not the page
    @previous = @previous.layout if @layoutShouldChange && !@layout

  #
  # This is required by {Joosy.Modules.Renderer}.
  #
  # Sets the base template dir to app_name/templates/pages
  #
  __renderSection: ->
    'pages'

  #
  # Unlike widget that injects straightforwardly into given container
  # page injects itself into the content of Layout and uses given container
  # as a fallback for cases when no Layout has been set
  #
  __bootstrapDefault: (applicationContainer) ->
    @__bootstrap @layout, @__nestingMap(), @layout?.content() || applicationContainer

# AMD wrapper
if define?.amd?
  define 'joosy/page', -> Joosy.Page
