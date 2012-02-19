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
    context = new Joosy.Modules.Events.SynchronizationContext(this)
    block.call(this, context)
    
    @wait context.expectations, => context.after.call(this)

    context.actions.each (data) =>
      data[0].call this, =>
        @trigger data[1]
        
#
# Internal representation of {Joosy.Modules.Events#synchronize} context
#
# @see Joosy.Modules.Events#synchronize
#
class Joosy.Modules.Events.SynchronizationContext
  @uid = 0

  constructor: (@parent) ->
    @expectations = []
    @actions = []

  #
  # Internal simple counter to separate given synchronization actions
  #
  uid: ->
    @constructor.uid += 1

  #
  # Registeres another async function that should be synchronized
  #
  # @param [Function] action        `(Function) -> null` to call.
  #   Should call given function to mark itself complete.
  #
  do: (action) ->
    event = "synchro-#{@uid()}"
    @expectations.push event
    @actions.push [action, event]

  #
  # Registers finalizer: the action that will be called when all do-functions 
  #   marked themselves as complete.
  #
  # @param [Function] after       Function to call.
  #
  after: (@after) ->
