Joosy.Modules.Events =
  wait: (events, callback) ->
    events = events.split /\s+/ if Object.isString events

    @__oneShotEvents ||= []
    @__oneShotEvents.push [events, callback]

  bind: (events, callback) ->
    events = events.split /\s+/

    @__boundEvents ||= []
    @__boundEvents.push [events, callback]

  unbind: (target) ->
    for [events, callback], index in @__boundEvents
      if callback == target
        @__boundEvents.splice index, 1
        return

  trigger: (event) ->
    Joosy.Modules.Log.debugAs @, "Event #{event} triggered"
    if @__oneShotEvents
      for [events, callback], index in @__oneShotEvents
        position = events.indexOf event
        if position >= 0
          events.splice position, 1

        if events.length == 0
          @__oneShotEvents.splice index, 1

          callback()

    if @__boundEvents
      for [events, callback] in @__boundEvents
        if events.has event
          callback()
          
  synchronize: (block) ->
    context = new Joosy.SynchronizationContext(this)
    block.call(this, context)
    
    @wait context.expectations, => context.after.call(this)

    context.actions.each (data) =>
      data[0].call this, =>
        @trigger data[1]


class Joosy.SynchronizationContext
  @uid = 0
  
  constructor: (@parent) ->
    @expectations = []
    @actions = []
  
  uid: ->
    @constructor.uid += 1
  
  do: (action) ->
    event = "synchro-#{@uid()}"
    @expectations.push event
    @actions.push [action, event]
  
  after: (@after) ->
