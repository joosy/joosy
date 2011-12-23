@Preloader =
  start: false
  complete: false

  receive: (url, callback) ->
    head   = document.getElementsByTagName("head")[0]
    script = document.createElement("script")
    script.src = url #+ "&rand=" + Math.random()

    done = false

    proceed = ->
      if ( !done && (!this.readyState ||
            this.readyState == "loaded" || this.readyState == "complete") )

        done = true and callback() if callback
        script.onload = script.onreadystatechange = null

    script.onload = script.onreadystatechange = proceed

    head.appendChild(script)
    return undefined

  load: (libraries) =>
    Preloader.start() if Preloader.start

    if libraries.length > 0
      Preloader.receive libraries.shift()[0], => Preloader.load(libraries)
    else
      Preloader.complete() if Preloader.complete