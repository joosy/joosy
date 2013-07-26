#= require joosy/core/joosy

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
  wait: (name, events, callback) ->
    @__oneShotEvents ||= {}

    # unnamed binding
    if Object.isFunction(events)
      callback = events
      events   = name
      name     = Object.keys(@__oneShotEvents).length.toString()

    @__oneShotEvents[name] = [@__splitEvents(events), callback]
    name

  #
  # Removes waiter action
  #
  # @param [Function] target            Name of waiter to unbind
  #
  unwait: (target) ->
    delete @__oneShotEvents[target]

  #
  # Binds action to run each time any of given event was triggered
  #
  # @param [String|Array] events        List of events separated by space
  # @param [Function] callback          Action to run on trigger
  # @param [Hash] options               Options
  #
  bind: (name, events, callback) ->
    @__boundEvents ||= {}

    # unnamed binding
    if Object.isFunction(events)
      callback = events
      events   = name
      name     = Object.keys(@__boundEvents).length.toString()

    @__boundEvents[name] = [@__splitEvents(events), callback]
    name

  #
  # Unbinds action from runing on trigger
  #
  # @param [Function] target            Name of bind to unbind
  #
  unbind: (target) ->
    delete @__boundEvents[target]

  #
  # Triggers event for {bind} and {wait}
  #
  # @param [String]           Name of event to trigger
  #
  trigger: (event, data...) ->
    Joosy.Modules.Log.debugAs @, "Event #{event} triggered"

    if @__oneShotEvents
      fire = []
      for name, [events, callback] of @__oneShotEvents
        events.remove event
        if events.length == 0
          fire.push name
      fire.each (name) =>
        callback = @__oneShotEvents[name][1]
        delete @__oneShotEvents[name]
        callback data...

    if @__boundEvents
      for name, [events, callback] of @__boundEvents
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
    context = new Joosy.Events.SynchronizationContext(@)
    block.call(@, context)

    if context.expectations.length == 0
      context.after.call(@)
    else
      @wait context.expectations, => context.after.call(@)
      context.actions.each (data) =>
        data[0].call @, =>
          @trigger data[1]

  __splitEvents: (events) ->
    if Object.isString events
      if events.isBlank()
        events = []
      else
        events = events.trim().split /\s+/

    unless Object.isArray(events) && events.length > 0
      throw new Error "#{Joosy.Module.__className @}> bind invalid events: #{events}"

    events

#
# Events namespace
#
# Creates unified collection of bindings to a particular instance
# that can be unbinded alltogether
#
# @example
#   namespace = Joosy.Events.Namespace(something)
#
#   namespace.bind 'event1', ->
#   namespace.bind 'event2', ->
#   namespace.unbind() # unbinds both bindings
#
class Joosy.Events.Namespace
  #
  # @param [Object] @parent         Any instance that can trigger events
  #
  constructor: (@parent) ->
    @bindings = []

  bind: (args...) -> @bindings.push @parent.bind(args...)
  unbind: ->
    @parent.unbind b for b in @bindings
    @bindings = []

#
# Internal representation of {Joosy.Modules.Events.synchronize} context
#
# @see Joosy.Modules.Events.synchronize
#
class Joosy.Events.SynchronizationContext
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
