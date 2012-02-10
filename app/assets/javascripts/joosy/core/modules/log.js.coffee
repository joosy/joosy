Joosy.Modules.Log =
  log: (args...) ->
    return unless console?

    if console.log.apply?
      args.unshift "Joosy>"
      console.log args...
    else
      console.log args.first()

  debug: (args...) ->
    return unless Joosy.debug
    @log args...

  debugAs: (context, string, args...) ->
    return unless Joosy.debug
    context = Joosy.Module.__className(context) || 'unknown context'
    @debug "#{context}> #{string}", args...
