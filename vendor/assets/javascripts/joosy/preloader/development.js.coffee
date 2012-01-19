@Preloader =
  receive: (url, callback) ->
    head   = document.getElementsByTagName("head")[0]
    script = document.createElement("script")
    script.src = url# + (if url.match(/\?/) then '&' else '?') + "rand=" + Math.random()

    done = false

    proceed = ->
      if ( !done && (!this.readyState ||
            this.readyState == "loaded" || this.readyState == "complete") )

        done = true and callback() if callback
        script.onload = script.onreadystatechange = null

    script.onload = script.onreadystatechange = proceed

    head.appendChild(script)
    return undefined

  load: (libraries) ->
    @start?.call window

    if libraries.length > 0
      @receive libraries.shift()[0], => @load(libraries)
    else
      @complete?.call window