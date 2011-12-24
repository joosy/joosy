@Joosy ?= {}
@Joosy.Modules = {}

Joosy.Beautifier =
  beautifiers: []

  add: (callback) -> @beautifiers.push(callback)
  go: -> b() for b in @beautifiers

Joosy.namespace = (name, generator=false) ->
  name  = name.split('.')
  space = window
  space = space[part] ?= {} for part in name

  generator = generator.apply(space) if generator?

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
  callback() if images.length == 0

  ticks  = images.length
  result = []

  for p in images
    result.push $('<img/>').attr('src', p).load ->
      callback?() if (ticks -= 1) == 0

  return result

Joosy.buildUrl = (url, params) ->
  params_string = []
  _(params).each (value, key) -> params_string.push("#{key}=#{value}")
  params_string = params_string.join('&')

  hash = url.match(/\#.*$/)
  hash = if hash then hash[0] else false

  url = url.replace(hash, '') if hash
  url = url + "?" if url.indexOf("?") == -1

  url = "#{url}&#{params_string}"

  url = url + hash if hash

  return url
