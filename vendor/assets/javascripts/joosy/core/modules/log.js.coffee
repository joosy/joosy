Joosy.Modules.Log =
  log: (args...) ->
    #trace = true
    #return unless trace
    # - wtf?
  
    return if typeof console is 'undefined'

    if console.log.apply?
      args.unshift "Joosy>"
      console.log(args...)
    else
      console.log(args.first())
  
  debug: (args...) ->
    @log(args...) if Joosy.debug