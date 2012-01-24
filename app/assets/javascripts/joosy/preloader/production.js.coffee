#= require base64

window.globalEval = (src) ->
  if window.execScript
    window.execScript src
  else
    fn = ->
      window.eval.call window,src
    fn()

@Preloader =
  force: false
  prefix: "cache:"

  libraries: []
  counter: 0

  complete: false

  ajax: (url, size, callback) ->
    if window.XMLHttpRequest
      x = new XMLHttpRequest
    else
      x = new ActiveXObject 'Microsoft.XMLHTTP'
    
    x.open 'GET', url, 1

    x.onreadystatechange = () ->
      if callback? && x.readyState > 3
        clearInterval(interval)
        callback(x)

    if @progress
      interval = setInterval =>
        try
          @progress.call window, Math.round((x.responseText.length / size) * (@counter / @libraries.length) * 100)
        catch e
          # ... IE?
      , 100
      
    x.send()

  restore: ->
    for name, i in @libraries
      code = window.localStorage.getItem(name)
      window.globalEval if window.navigator.appName == "Microsoft Internet Explorer" then Base64.decode(code) else code
    @complete?.call window, true

  download: (libraries) ->
    if libraries.length > 0
      @counter += 1

      lib  = libraries.shift()
      url  = lib[0]
      size = lib[1]

      @ajax url, size, (xhr) =>
        code = xhr.responseText
        window.localStorage.setItem @prefix+url, (if window.navigator.appName == "Microsoft Internet Explorer" then Base64.encode(code) else code)
        window.globalEval xhr.responseText
        @download libraries
    else
      @clean()
      @complete?.call window, false

  load: (libraries) ->
    @libraries = libraries.slice()

    for lib, i in @libraries
      @libraries[i] = @prefix+lib[0]

    if !@force && @check()
      @restore()
    else
      @start?.call window
      @download libraries

  check: ->
    flag = true
    for name, i in @libraries
      flag &&= window.localStorage.getItem(name)?
    flag

  clean: ->
    removed = 0

    for element, i in window.localStorage
      key = window.localStorage.key(i-removed)

      if key.indexOf(@prefix) == 0 && @libraries.indexOf(key) < 0
        window.localStorage.removeItem key
        removed += 1