#= require joosy/joosy

# @private
class SynchronizationContext
  constructor:    -> @actions = []
  do: (action)    -> @actions.push action
  after: (@after) ->

#
# @private
# Events namespace
#
# Creates unified collection of bindings to a particular instance
# that can be unbinded alltogether
#
# @example
#   namespace = new Namespace(something)
#
#   namespace.bind 'event1', ->
#   namespace.bind 'event2', ->
#   namespace.unbind() # unbinds both bindings
#
class Namespace
  #
  # @param [Object] @parent         Any instance that can trigger events
  #
  constructor: (@parent) ->
    @bindings = []

  bind: (args...) ->
    @bindings.push @parent.bind(args...)

  unbind: ->
    @parent.unbind b for b in @bindings
    @bindings = []


#
# Basic events implementation
#
# @mixin
#
Joosy.Modules.Events =

  #
  # Creates events namespace
  #
  # @example
  #   namespace = @entity.eventsNamespace, ->
  #     @bind 'action1', ->
  #     @bind 'action2', ->
  #
  #   namespace.unbind()
  #
  eventsNamespace: (actions) ->
    namespace = new Namespace @
    actions?.call?(namespace)
    namespace

  #
  # Waits for the list of given events to happen at least once. Then runs callback.
  #
  # @param [String|Array] events        List of events to wait for separated by space
  # @param [Function] callback          Action to run when all events were triggered at least once
  # @param [Hash] options               Options
  #
  wait: (name, events, callback) ->
    @__oneShotEvents = {} unless @hasOwnProperty('__oneShotEvents')

    # unnamed binding
    if Object.isFunction(events)
      callback = events
      events   = name
      name     = Object.keys(@__oneShotEvents).length.toString()

    events = @__splitEvents(events)

    if events.length > 0
      @__oneShotEvents[name] = [events, callback]
    else
      callback()

    name

  #
  # Removes waiter action
  #
  # @param [Function] target            Name of waiter to unbind
  #
  unwait: (target) ->
    delete @__oneShotEvents[target] if @hasOwnProperty '__oneShotEvents'

  #
  # Binds action to run each time any of given event was triggered
  #
  # @param [String|Array] events        List of events separated by space
  # @param [Function] callback          Action to run on trigger
  # @param [Hash] options               Options
  #
  bind: (name, events, callback) ->
    @__boundEvents = {} unless @hasOwnProperty '__boundEvents'

    # unnamed binding
    if Object.isFunction(events)
      callback = events
      events   = name
      name     = Object.keys(@__boundEvents).length.toString()

    events = @__splitEvents(events)

    if events.length > 0
      @__boundEvents[name] = [events, callback]
    else
      callback()

    name

  #
  # Unbinds action from runing on trigger
  #
  # @param [Function] target            Name of bind to unbind
  #
  unbind: (target) ->
    delete @__boundEvents[target] if @hasOwnProperty '__boundEvents'

  #
  # Triggers event for {bind} and {wait}
  #
  # @param [String]           Name of event to trigger
  #
  trigger: (event, data...) ->
    Joosy.Modules.Log.debugAs @, "Event #{event} triggered"

    if Object.isObject event
      remember = event.remember
      event    = event.name
    else
      remember = false

    if @hasOwnProperty '__oneShotEvents'
      fire = []
      for name, [events, callback] of @__oneShotEvents
        events.remove event
        if events.length == 0
          fire.push name
      fire.each (name) =>
        callback = @__oneShotEvents[name][1]
        delete @__oneShotEvents[name]
        callback data...

    if @hasOwnProperty '__boundEvents'
      for name, [events, callback] of @__boundEvents
        if events.any event
          callback data...

    if remember
      @__triggeredEvents = {} unless @hasOwnProperty '__triggeredEvents'
      @__triggeredEvents[event] = true

  #
  # Runs set of callbacks finializing with result callback
  #
  # @example Basic usage
  #   @synchronize (context) ->
  #     context.do (done) -> done()
  #     context.do (done) -> done()
  #     context.after ->
  #       console.log 'Success!'
  #
  # @param [Function] block           Configuration block (see example)
  #
  synchronize: (block) ->
    context = new SynchronizationContext
    counter = 0

    block(context)

    if context.actions.length == 0
      context.after.call(@)
    else
      context.actions.each (action) =>
        action.call @, ->
          if ++counter >= context.actions.length
            context.after.call(@)

  __splitEvents: (events) ->
    if Object.isString events
      if events.isBlank()
        events = []
      else
        events = events.trim().split /\s+/

    if @hasOwnProperty '__triggeredEvents'
      events = events.findAll (e) => !@__triggeredEvents[e]

    events

# AMD wrapper
if define?.amd?
  define 'joosy/modules/events', -> Joosy.Modules.Events