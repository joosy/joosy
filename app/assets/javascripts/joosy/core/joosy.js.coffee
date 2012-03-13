#
# All the tiny core stuff
#
# @module
#
@Joosy =
  #
  # Core modules container
  #
  Modules: {}
  
  #
  # Resources container
  #
  Resource: {}
  
  #
  # Templaters container
  #
  Templaters: {}

  #
  # If enabled Joosy will log to console a lot of 'in progress' stuff
  #
  debug: false

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
      space = space[part] ?= {}

    if generator
      generator = generator.apply space
    for key, klass of space
      if space.hasOwnProperty(key) &&
         Joosy.Module.hasAncestor klass, Joosy.Module
        klass.__namespace__ = name

  #
  # Registeres given methods as a helpers inside a given set
  #
  # @param [String] name            Helpers set keyword
  # @param [Boolean] generator      Helpers content
  #
  helpers: (name, generator) ->
    Joosy.namespace "Joosy.Helpers.#{name}", generator

  #
  # Scary `hello world`
  #
  test: ->
    text = "Hi :). I'm Joosy. And everything is just fine!"

    if console
      console.log text
    else
      alert text

  #
  # Generates UUID
  #
  uuid: ->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else r & 3 | 8
      v.toString 16
    .toUpperCase()

  #
  # Preloads sets of images then runs callback
  #
  # @param [Array<String>] images             Images paths
  # @param [Function] callback                Action to run when every picture was loaded (or triggered an error)
  #
  preloadImages: (images, callback) ->
    unless Object.isArray(images)
      images = [images]
    if images.length == 0
      callback()

    ticks   = images.length
    result  = []
    checker = ->
      if (ticks -= 1) == 0
        callback?()

    for p in images
      result.push $('<img/>').load(checker).error(checker).attr('src', p)

    result

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

    Object.each params, (key, value) ->
      paramsString.push "#{key}=#{value}"

    hash = url.match(/(\#.*)?$/)[0]
    url  = url.replace /\#.*$/, ''
    if !paramsString.isEmpty() && !url.has(/\?/)
      url  = url + "?"

    paramsString = paramsString.join '&'
    if !paramsString.isBlank() && url.last() != '?'
      paramsString = '&' + paramsString

    url + paramsString + hash