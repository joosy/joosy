#= require_self
#= require joosy/module

#
# All the tiny core stuff
#
# @mixin
#
@Joosy =
  #
  # Core modules container
  #
  Modules: {}

  #
  # Resources container
  #
  Resources: {}

  #
  # Templaters container
  #
  Templaters: {}

  #
  # Helpers container
  #
  Helpers: {}

  #
  # Events namespace
  #
  Events: {}


  ### Global settings ###

  #
  # Debug mode
  #
  debug: (value) ->
    if value?
      @__debug = value
    else
      !!@__debug

  #
  # Templating engine
  #
  templater: (value) ->
    if value?
      @__templater = value
    else
      throw new Error "No templater registered" unless @__templater
      @__templater

  ### Global helpers ###

  #
  # Registeres anything inside specified namespace (objects chain starting from `window`)
  #
  # @example Basic usage
  #   Joosy.namespace 'foobar', ->
  #     class @RealThing
  #
  #   foo = new foobar.RealThing
  #
  # @param [String] name            Namespace keyword
  # @param [Boolean] generator      Namespace content
  #
  namespace: (name, generator=false) ->
    name  = name.split '.'
    space = window
    for part in name
      space = space[part] ?= {} if part.length > 0

    if generator
      generator = generator.apply space
    for key, klass of space
      if space.hasOwnProperty(key) &&
          Joosy.Module.hasAncestor(klass, Joosy.Module)
        klass.__namespace__ = name

  #
  # Registeres given methods as a helpers inside a given set
  #
  # @param [String] name            Helpers set keyword
  # @param [Boolean] generator      Helpers content
  #
  helpers: (name, generator) ->
    Joosy.Helpers[name] ||= {}
    generator.apply Joosy.Helpers[name]

  #
  # Generates ID unique within current run
  #
  uid: ->
    @__uid ||= 0
    "__joosy#{@__uid++}"

  #
  # Generates UUID
  #
  uuid: ->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else r & 3 | 8
      v.toString 16
    .toUpperCase()

  ### Shortcuts ###

  #
  # Runs set of callbacks finializing with result callback
  #
  # @example Basic usage
  #   Joosy.synchronize (context) ->
  #     contet.do (done) -> done()
  #     contet.do (done) -> done()
  #     content.after ->
  #       console.log 'Success!'
  #
  # @param [Function] block           Configuration block (see example)
  #
  synchronize: ->
    unless Joosy.Modules.Events
      console.error "Events module is required to use `Joosy.synchronize'!"
    else
      Joosy.Modules.Events.synchronize arguments...

  #
  # Basic URI builder. Joins base path with params hash
  #
  # @param [String] url         Base url
  # @param [Hash] params        Parameters to join
  #
  # @example Basic usage
  #   Joosy.buildUrl 'http://joosy.ws/#!/test', {foo: 'bar'}    # http://joosy.ws/?foo=bar#!/test
  #
  buildUrl: (url, params) ->
    paramsString = []
    paramsString.push "#{key}=#{value}" for key, value of params

    hash = url.match(/(\#.*)?$/)[0]
    url  = url.replace /\#.*$/, ''
    if paramsString.length != 0 && url.indexOf('?') == -1
      url  = url + "?"

    paramsString = paramsString.join '&'
    if paramsString.length > 0 && url[url.length-1] != '?'
      paramsString = '&' + paramsString

    url + paramsString + hash

  #
  # @private
  #
  __initializeDeferred: ->
    @__useSetTimeoutFallback = true

    if window.postMessage?
      @__useSetTimeoutFallback = false
      @__invoking = false
      @__callbackQueue = []
      @__callbackNonces = []

      listener = (ev) =>
        if ev.source == window && ev.data == 'joosy-invoke-immediate'
          @__invokeCallbacks()

      window.addEventListener 'message', listener, true

      # Test if postMessage implementation is synchronous (IE8-like) or not
      # If it is, fall back to setTimeout

      synchronous = false
      @callDeferred =>
        synchronous = true

      if synchronous
        @__useSetTimeoutFallback = true
        delete @__callbackQueue
        window.removeEventListener 'message', listener, true

  #
  # Invoke callback after completion of the current callback
  # Functionally similar to setTimeout(callback, 0)
  #
  # @param   [Function] callback Callback
  # @return  [Integer]           Callback ID
  #
  callDeferred: (callback) ->
    if @__useSetTimeoutFallback
      setTimeout callback, 0
    else
      allocated = undefined
      unless @__invoking
        for item, index in @__callbackQueue
          unless item?
            allocated = index
            break

      unless allocated?
        allocated = @__callbackQueue.length

      @__callbackQueue[allocated] = callback
      @__callbackNonces[allocated] ||= 0
      nonce = @__callbackNonces[allocated]

      window.postMessage 'joosy-invoke-immediate', '*'

      (allocated << 16) | (nonce & 65535)

  #
  # Cancel deferred callback
  #
  # @param   [Integer]  Callback ID
  #
  cancelDeferred: (handle) ->
    if @__useSetTimeoutFallback
      clearTimeout handle
    else
      index = handle >> 16
      nonce = handle & 65535

      if nonce != @__callbackNonces[index]
        throw new Error "Attempted to cancel stale handle"

      @__callbackNonces[index] = (@__callbackNonces[index] + 1) & 65535
      @__callbackQueue[index] = null

    undefined

  #
  # @private
  #
  __invokeCallbacks: ->
    try
      @__invoking = true
      lastIndex = @__callbackQueue.length

      for callback, callbackIndex in @__callbackQueue
        break if callbackIndex > lastIndex

        if callback?
          @__callbackNonces[callbackIndex] = (@__callbackNonces[callbackIndex] + 1) & 65535
          @__callbackQueue[callbackIndex] = null

          try
            callback()
          catch e
            console?.error? "Uncatched exception in the callDeferred callback: ", e
    finally
      @__invoking = false


Joosy.__initializeDeferred()

if define?.amd?
  define 'joosy', -> Joosy