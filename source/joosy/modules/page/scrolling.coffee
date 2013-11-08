#= require ../page

#
# The auto-scrolling filters for Page (or possibly widgets)
#
# @see Joosy.Page
# @mixin
#
Joosy.Modules.Page.Scrolling =

  included: ->
    @afterLoad ->
      @__performScrolling() if @__scrollElement

    @paint (complete) ->
      @__fixHeight() if @__scrollElement && @__scrollSpeed != 0
      complete()

  ClassMethods:
    #
    # Sets the position where page will be scrolled to after load.
    #
    # @note If you use animated scroll joosy will atempt to temporarily fix the
    #   height of your document while scrolling to prevent jump effect.
    #
    # @param [jQuery] element         Element to scroll to
    # @param [Hash] options
    #
    # @option options [Integer] speed       Sets the animation duration (500 is default)
    # @option options [Integer] margin      Defines the margin from element position.
    #   Can be negative.
    #
    # @example
    #   class TestPage extends Joosy.Page
    #     @scroll '#header', speed: 300, margin: -100
    #
    scroll: (element, options={}) ->
      @::__scrollElement = element
      @::__scrollSpeed = options.speed || 500
      @::__scrollMargin = options.margin || 0

  InstanceMethods:
    #
    # Scrolls page to stored positions
    #
    # @private
    #
    __performScrolling: ->
      scroll = $(@__extractSelector @__scrollElement).offset()?.top + @__scrollMargin
      Joosy.Modules.Log.debugAs @, "Scrolling to #{@__extractSelector @__scrollElement}"
      $('html, body').animate {scrollTop: scroll}, @__scrollSpeed, =>
        if @__scrollSpeed != 0
          @__releaseHeight()

    #
    # Freezes the page height through $(html).
    #
    # Required to implement better {Joosy.Modules.Page.Scrolling.scroll} behavior.
    #
    # @private
    #
    __fixHeight: ->
      $('html').css 'min-height', $(document).height()

    #
    # Undoes {Joosy.Modules.Page.Scrolling#__fixHeight}
    #
    # @private
    #
    __releaseHeight: ->
      $('html').css 'min-height', ''