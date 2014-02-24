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

    timer = window.setTimeout =>
      if @__timeouts?
        index = @__timeouts.indexOf timer
        @__timeouts.splice index if index != -1

      action()
    , timeout
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

    if @__timeouts?
      index = @__timeouts.indexOf timer
      @__timeouts.splice index if index != -1

  #
  # Clears inteval preventing callback from execution
  #
  # @param [Integer] timer            Timer
  #
  clearInterval: (timer) ->
    window.clearInterval timer

    if @__intervals?
      index = @__intervals.indexOf timer
      @__intervals.splice index if index != -1

  #
  # Invoke callback after completion of the current callback
  # Functionally similar to setTimeout(callback, 0)
  #
  # @param   [Function] callback Callback
  # @return  [Integer]           Callback ID
  #
  callDeferred: (callback) ->
    @__deferreds ||= []

    deferred = Joosy.callDeferred =>
      if @__deferreds?
        index = @__deferreds.indexOf deferred
        @__deferreds.splice index if index != -1

      callback()

    @__deferreds.push deferred

    deferred

  #
  # Cancel deferred callback
  #
  # @param   [Integer] timer  Callback ID
  #
  cancelDeferred: (timer) ->
    Joosy.cancelDeferred timer

    if @__deferreds?
      index = @__deferreds.indexOf timer
      @__deferreds.splice index if index != -1

  #
  # Drops all registered timeouts and intervals for this object
  #
  # @private
  #
  __clearTime: ->
    if @__intervals?
      for entry in @__intervals
        window.clearInterval entry

      delete @__intervals

    if @__timeouts?
      for entry in @__timeouts
        window.clearTimeout entry

      delete @__timeouts

    if @__deferreds?
      for entry in @__deferreds
        Joosy.cancelDeferred entry

      delete @__deferreds

# AMD wrapper
if define?.amd?
  define 'joosy/modules/time_manager', -> Joosy.Modules.TimeManager