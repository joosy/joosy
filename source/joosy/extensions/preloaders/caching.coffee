#
# Preloader for libraries with localStorage cache
#
# @note The `start` callback will only be called if loading required.
#   While working with cache, `complete` is the only callback that will be triggered.
#
# @example Basic usage
#   libraries = [['/test1.js', 100], ['/test2.js', 500]] #100, 500 - size in bytes
#
#   CachingPreloader.load libraries,
#     start:    -> console.log 'preloading started'
#     progress: (percent) -> console.log "#{percent}% loaded"
#     complete: -> console.log 'preloading finished'
#
# @mixin
#
@CachingPreloader =
  #
  # If set to true, localStorage cache will be avoided
  #
  force: false

  #
  # Prefix for localStorage keys
  #
  prefix: "cache:"

  #
  # Number of libraries have been loaded (increases after lib was loaded)
  #
  counter: 0

  #
  # Loads (or takes from cache) set of libraries using xhr and caches them in localStorage
  # See class description for example of usage
  #
  # @param [Array] 2-levels array of libraries URLs i.e. [['/test1.js', 10],['/test2.js', 20]]
  #   Second param of inner level is a size of script in bytes. Can be undefined.
  # @param [Hash] Available options:
  #   * start: `() -> null` to call before load starts
  #   * progress: `(int percents) -> null` to call each 100ms of load in progress
  #   * complete: `() -> null` to call after load completes
  #
  load: (libraries, options={}) ->
    @[key] = val for key, val of options
    @libraries = libraries.slice()

    for lib, i in @libraries
      @libraries[i] = @prefix+lib[0]

    if !@force && @check()
      @restore()
    else
      @start?.call window
      @clean()
      @download libraries

  #
  # Checks if we can load libraries or have to download them over
  #
  check: ->
    flag = true
    for name, i in @libraries
      flag &&= window.localStorage.getItem(name)?
    flag

  #
  # Escapes non-printable terminal chars before storing to localStorage to prevent IE bug
  #
  # @param [String] String, that will be prepared for localStorage
  #
  escapeStr: (str) ->
    str.replace(new RegExp("\u0001", 'g'), "\\u0001").replace(new RegExp("\u000B", 'g'), "\\u000B")

  #
  # Gets sources of scripts from localStorage and evals them
  #
  restore: ->
    for name, i in @libraries
      window.evalGlobaly window.localStorage.getItem name
    @complete?.call window, true

  #
  # Loads set of libraries using xhr and caches them in localStorage
  #
  # @param [Array] 2-levels array of libraries URLs i.e. [['/test1.js', 100],['/test2.js', 500]]
  #   Second param of inner level is a size of script in bytes. Can be undefined.
  #
  download: (libraries) ->
    if libraries.length > 0
      @counter += 1

      lib  = libraries.shift()
      url  = lib[0]
      size = lib[1]

      @ajax url, size, (xhr) =>
        code = xhr.responseText
        if window.navigator.appName == "Microsoft Internet Explorer"
          code = @escapeStr code
        window.localStorage.setItem @prefix+url, code
        window.evalGlobaly xhr.responseText
        @download libraries
    else
      @complete?.call window

  #
  # Runs XHR request to get single script body
  # Binds poller to call @progress each 100ms if possible (not IE *doh*)
  #
  # @param [String] URL to download from
  # @param [Float] Expected size of download (to calculate percents)
  #   Size can not be taken from headers since we are supposed to get gziped content
  # @param [Function] `(xhr) -> null` to call after script was loaded
  #
  ajax: (url, size, callback) ->
    if window.XMLHttpRequest
      x = new XMLHttpRequest
    else
      x = new ActiveXObject 'Microsoft.XMLHTTP'

    x.open 'GET', url, 1

    x.onreadystatechange = () =>
      if x.readyState > 3
        clearInterval @interval
        callback? x

    if @progress
      poller = =>
        try
          @progress.call window, Math.round((x.responseText.length / size) * (@counter / @libraries.length) * 100)
        catch e
          # ... IE?

      @interval = setInterval poller, 100

    x.send()

  #
  # Searches through localStorage for outdated entries with our prefix and removes them
  #
  clean: ->
    i = 0

    find = (arr, obj) ->
      (return i if obj == x) for x in arr
      return -1

    while i < window.localStorage.length && key = window.localStorage.key(i)
      if key.indexOf(@prefix) == 0 && find(@libraries, key) < 0
        window.localStorage.removeItem key
      else
        i += 1

#
# Evals source at a global scope
# Don't touch it! It should be window's property, or FF3.6 will execute scripts on preloader context.
#
# @param [String] JS source to execute
#
window.evalGlobaly = (src) ->
  return if src.length == 0
  if window.execScript
    window.execScript src
  else
    window.eval src

@Preloader = @CachingPreloader
