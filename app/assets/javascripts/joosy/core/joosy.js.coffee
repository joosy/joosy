@Joosy =
  Modules: {}
  Resource: {}
  Templaters: {}

  debug: false

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

  helpers: (name, generator) ->
    Joosy.namespace "Joosy.Helpers.#{name}", generator

  test: ->
    text = "Hi :). I'm Joosy. And everything is just fine!"

    if console
      console.log text
    else
      alert text

  uuid: ->
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = if c is 'x' then r else r & 3 | 8
      v.toString 16
    .toUpperCase()

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