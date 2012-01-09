Joosy.Modules.Log =
  log: (args...) ->
    trace = true

    return unless trace
    return if typeof console is 'undefined'

    args.unshift "Joosy>"
    console.log(args...)
  
  debug: (args...) ->
    @log(args...) if Joosy.debug