#
# Wrappers for console.log
#
# @mixin
#
Joosy.Modules.Log =

  #
  # Checks if console is available and proxies given arguments directly to `console.log`
  #
  log: (args...) ->
    return unless console?

    if console.log.apply?
      args.unshift "Joosy>"
      console.log args...
    else
      console.log args.first()

  #
  # Runs `log` if debug is active
  #
  debug: (args...) ->
    return unless Joosy.Application.debug
    @log args...

  #
  # Logs given message wrapping it with description of given object (class name)
  #
  # @param [Object] context           The class required to be described in log message
  # @param [String] string            Message to log
  #
  debugAs: (context, string, args...) ->
    return unless Joosy.Application.debug
    context = Joosy.Module.__className(context) || 'unknown context'
    @debug "#{context}> #{string}", args...
