@Preloader =
  force: false
  prefix: "cache:"

  libraries: []
  counter: 0

  progress: false
  start: false
  complete: false

  ajax: (url, size, callback) ->
    x = this.ActiveXObject
    x = new (if x then x else XMLHttpRequest)('Microsoft.XMLHTTP')

    x.open('GET', url, 1)
    x.setRequestHeader('Content-type','application/x-www-form-urlencoded')

    if Preloader.progress
      x.onprogress = (event) ->
        total = if size then size else event.total
        Preloader.progress Math.round(event.loaded / total * 100 * Preloader.counter / Preloader.libraries.length)

    x.onreadystatechange = () -> callback(x) if callback? && x.readyState > 3
    x.send()

  restore: ->
    for name, i in Preloader.libraries
      window.eval window.localStorage.getItem(name)
    Preloader.complete(true) if Preloader.complete

  download: (libraries) ->
    if libraries.length > 0
      Preloader.counter += 1

      lib  = libraries.shift()
      url  = lib[0]
      size = lib[1]

      Preloader.ajax url, size, (xhr) ->
        window.localStorage.setItem(Preloader.prefix+url, xhr.responseText)
        window.eval(xhr.responseText)
        Preloader.download(libraries)
    else
      Preloader.clean()
      Preloader.complete(false) if Preloader.complete

  load: (libraries) ->
    Preloader.libraries = libraries.slice()

    for lib, i in Preloader.libraries
      Preloader.libraries[i] = Preloader.prefix+lib[0]

    if !Preloader.force && Preloader.check()
      Preloader.restore()
    else
      Preloader.start() if Preloader.start
      Preloader.download(libraries)

  check: ->
    flag = true
    for name, i in Preloader.libraries
      flag &&= window.localStorage.getItem(name)?
    flag

  clean: ->
    removed = 0

    for element, i in window.localStorage
      key = window.localStorage.key(i-removed)

      if key.indexOf(Preloader.prefix) == 0 && Preloader.libraries.indexOf(key) < 0
        window.localStorage.removeItem(key)
        removed += 1