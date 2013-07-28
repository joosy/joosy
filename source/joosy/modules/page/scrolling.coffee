Joosy.Modules.Page_Scrolling =

  included: ->
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
    @scroll = (element, options={}) ->
      @::__scrollElement = element
      @::__scrollSpeed = options.speed || 500
      @::__scrollMargin = options.margin || 0

  #
  # Scrolls page to stored positions
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
  # Required to implement better {Joosy.Page.scroll} behavior.
  #
  __fixHeight: ->
    $('html').css 'min-height', $(document).height()

  #
  # Undo {#__fixHeight}
  #
  __releaseHeight: ->
    $('html').css 'min-height', ''