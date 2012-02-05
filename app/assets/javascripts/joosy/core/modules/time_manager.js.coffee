Joosy.Modules.TimeManager =
  setTimeout: (timeout, action) ->
    @__timeouts ||= []

    timer = window.setTimeout (=> action()), timeout
    @__timeouts.push timer

    timer

  setInterval: (delay, action) ->
    @__intervals ||= []

    timer = window.setInterval (=> action()), delay
    @__intervals.push timer

    timer

  __clearTime: ->
    if @__intervals
      for entry in @__intervals
        window.clearInterval entry

    if @__timeouts
      for entry in @__timeouts
        window.clearTimeout entry
