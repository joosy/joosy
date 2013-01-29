#
# Basic events implementation
#
# @mixin
#
Joosy.Modules.Events =

  #
  # Waits for the list of given events to happen at least once. Then runs callback.
  #
  # @param [String|Array] events        List of events to wait for separated by space
  # @param [Function] callback          Action to run when all events were triggered at least once
  # @param [Hash] options               Options
  #
  # @option options [Boolean] unique    Call has no effect if true and the given pair
  #                                     of events and callback is already set up
  #
  wait: (events, callback, options = {}) ->
    events = @__splitEvents events
    @__validateEvents events

    return if options.unique && @__isBound(events, callback, true)

    @__oneShotEvents ||= []
    @__oneShotEvents.push [events, callback]

  #
  # Binds action to run each time any of given even was triggered
  #
  # @param [String|Array] events        List of events separated by space
  # @param [Function] callback          Action to run on trigger
  # @param [Hash] options               Options
  #
  # @option options [Boolean] unique    Call has no effect if true and the given pair
  #                                     of events and callback is already set up
  #
  bind: (events, callback, options = {}) ->
    events = @__splitEvents events
    @__validateEvents events

    return if options.unique && @__isBound(events, callback)

    @__boundEvents ||= []
    @__boundEvents.push [events, callback]

  #
  # Unbinds action from runing on trigger
  #
  # @param [Function] target            Action to unbind
  #
  unbind: (target) ->
    for [events, callback], index in @__boundEvents
      if callback == target
        @__boundEvents.splice index, 1
        return

  #
  # Triggers event for {bind} and {wait}
  #
  # @param [String]           Name of event to trigger
  #
  trigger: (event, data...) ->
    Joosy.Modules.Log.debugAs @, "Event #{event} triggered"
    if @__oneShotEvents
      fire = []
      for [events, callback], index in @__oneShotEvents
        events.remove event
        if events.length == 0
          fire.push index
      fire.each (index) =>
        callback = @__oneShotEvents[index][1]
        @__oneShotEvents.removeAt index
        callback data...
    if @__boundEvents
      for [events, callback] in @__boundEvents
        if events.any event
          callback data...

  #
  # Runs set of callbacks finializing with result callback
  #
  # @example Basic usage
  #   Joosy.synchronize (context) ->
  #     contet.do (done) -> done()
  #     contet.do (done) -> done()
  #     content.after ->
  #       console.log 'Success!'
  #
  # @param [Function] block           Configuration block (see example)
  #
  synchronize: (block) ->
    context = new Joosy.Modules.Events.SynchronizationContext(this)
    block.call(this, context)

    if context.expectations.length == 0
      context.after.call(this)
    else
      @wait context.expectations, => context.after.call(this)
      context.actions.each (data) =>
        data[0].call this, =>
          @trigger data[1]

  __splitEvents: (events) ->
    if Object.isString events
      if events.isBlank()
        []
      else
        events.trim().split /\s+/
    else
      events

  __validateEvents: (events) ->
    unless Object.isArray(events) && events.length > 0
      throw new Error "#{Joosy.Module.__className @}> bind invalid events: #{events}"

  __isBound: (events, callback, oneShot = false) ->
    haystack = if oneShot
      @__oneShotEvents
    else
      @__boundEvents

    return false unless haystack

    result = haystack.find (item) ->
      item[0].length == events.length &&
        item[0].subtract(events).isEmpty() &&
        item[1] == callback

    !!result

#
# Internal representation of {Joosy.Modules.Events.synchronize} context
#
# @see Joosy.Modules.Events.synchronize
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
