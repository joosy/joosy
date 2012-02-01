#
# Preloader for libraries using <script src> without any caching magic
#
# Example:
#   libraries = [['/test1.js'], ['/test2.js']]
#   InlinePreloader.load libraries,
#     start:    -> console.log 'preloading started'
#     complete: -> console.log 'preloading finished'
#
# @class InlinePreloader
#
@Preloader = @InlinePreloader =

  #
  # Loads set of libraries by adding <script src> to DOM head 
  # See class description for example of usage
  #
  # @param [Array] 2-levels array of libraries URLs i.e. [['/test1.js'],['/test2.js']]
  # @param [Hash] Available options:
  #   * start: `() -> null` to call before load starts: 
  #   * complete: `() -> null` to call after load completes
  #
  load: (libraries, options) ->    
    @[key] = val for key, val of options
    @start?.call window

    if libraries.length > 0
      @receive libraries.shift()[0], => @load(libraries)
    else
      @complete?.call window

  #
  # Loads one script by adding <script src> to DOM head
  #
  # @param [String] url to load script from
  # @param [Function] `() -> null` to call after script was loaded and executed
  #
  receive: (url, callback) ->
    head   = document.getElementsByTagName("head")[0]
    script = document.createElement("script")
    script.src = url

    done = false

    proceed = ->
      if ( !done && (!this.readyState ||
            this.readyState == "loaded" || this.readyState == "complete") )

        done = true and callback() if callback
        script.onload = script.onreadystatechange = null

    script.onload = script.onreadystatechange = proceed

    head.appendChild(script)
    return undefined