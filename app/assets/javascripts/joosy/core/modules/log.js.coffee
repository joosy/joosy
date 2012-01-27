Joosy.Modules.Log =
  log: (args...) ->
    return if typeof console is 'undefined'

    if console.log.apply?
      args.unshift "Joosy>"
      console.log(args...)
    else
      console.log(args.first())

  debug: (args...) ->
    @log(args...) if Joosy.debug

  debugAs: (context, string, args...) ->
    @debug "#{Joosy.Module.__className__(context) || 'unknown context'}> #{string}", args...