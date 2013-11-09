#= require joosy/joosy

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
  # @return [Integer]                 Timer
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
  # @return [Integer]                 Timer
  #
  setInterval: (delay, action) ->
    @__intervals ||= []

    timer = window.setInterval (=> action()), delay
    @__intervals.push timer

    timer

  #
  # Clears tmeout preventing callback from execution
  #
  # @param [Integer] timer            Timer
  #
  clearTimeout: (timer) ->
    window.clearTimeout timer

  #
  # Clears inteval preventing callback from execution
  #
  # @param [Integer] timer            Timer
  #
  clearInterval: (timer) ->
    window.clearInterval timer

  #
  # Drops all registered timeouts and intervals for this object
  #
  # @private
  #
  __clearTime: ->
    if @__intervals
      for entry in @__intervals
        window.clearInterval entry

    if @__timeouts
      for entry in @__timeouts
        window.clearTimeout entry

# AMD wrapper
if define?.amd?
  define 'joosy/modules/time_manager', -> Joosy.Modules.TimeManager