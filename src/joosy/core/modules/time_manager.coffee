#
# Comfortable and clever wrappers for timeouts management
#
# @mixin
#
Joosy.Modules.TimeManager =

  #
  # Registeres timeout for current object
  #
  # @param [Integer] timeout          Miliseconds to wait
  # @param [Function] action          Action to run on timeout
  #
  setTimeout: (timeout, action) ->
    @__timeouts ||= []

    timer = window.setTimeout (=> action()), timeout
    @__timeouts.push timer

    timer

  #
  # Registeres interval for current object
  #
  # @param [Integer] delay            Miliseconds between runs
  # @param [Function] action          Action to run
  #
  setInterval: (delay, action) ->
    @__intervals ||= []

    timer = window.setInterval (=> action()), delay
    @__intervals.push timer

    timer

  #
  # Drops all registered timeouts and intervals for this object
  #
  __clearTime: ->
    if @__intervals
      for entry in @__intervals
        window.clearInterval entry

    if @__timeouts
      for entry in @__timeouts
        window.clearTimeout entry
