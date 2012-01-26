@Joosy = Object.extended(if @Joosy? then @Joosy else {})

@Joosy.merge
  debug: false
  Modules: {}
  Resource: {}
  Templaters: {}

Joosy.Beautifier =
  beautifiers: []

  add: (callback) ->
    @beautifiers.push callback

  go: ->
    for b in @beautifiers
      b()

Joosy.namespace = (name, generator=false) ->
  name  = name.split('.')
  space = window
  space = space[part] ?= {} for part in name

  # A strange hack to add namespaces to Joosy.Module descendants
  Joosy.Module.__namespace__ = name
  generator = generator.apply(space) if generator
  delete Joosy.Module.__namespace__

Joosy.helpers = (name, generator) ->
  Joosy.namespace("Joosy.Helpers.#{name}", generator)

Joosy.test = ->
  text = "Hi :). I'm Joosy. And everything is just fine!"

  if console
    console.log text
  else
    alert text

Joosy.uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = if c is 'x' then r else r & 3 | 8
    v.toString 16
  .toUpperCase()

Joosy.preloadImages = (images, callback) ->
  images = [images] if !Object.isArray(images)
  callback() if images.length == 0

  ticks   = images.length
  result  = []
  checker = ->
    callback?() if (ticks -= 1) == 0

  for p in images
    result.push $('<img/>').load(checker).attr('src', p)

  result

Joosy.buildUrl = (url, params) ->
  paramsString = []

  Object.each params, (key, value) ->
    paramsString.push("#{key}=#{value}")

  hash = url.match(/(\#.*)?$/)[0]
  url  = url.replace(/\#.*$/, '')
  url  = url + "?" if !paramsString.isEmpty() && !url.has(/\?/)

  paramsString = paramsString.join('&')
  paramsString = '&' + paramsString if paramsString != '' && url.last() != '?'

  url + paramsString + hash