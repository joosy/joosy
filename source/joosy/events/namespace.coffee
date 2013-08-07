#
# Events namespace
#
# Creates unified collection of bindings to a particular instance
# that can be unbinded alltogether
#
# @see Joosy.Modules.Events
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
