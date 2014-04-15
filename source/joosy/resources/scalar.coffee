#
# The scalar value with the support of dynamic rendering
#
# @include Joosy.Modules.Events
# @extend  Joosy.Modules.Filters
#
# @example
#   data = Joosy.Resources.Scalar.build 1
#   data.get()                             # 1
#   data.set(2)                            # triggers 'changed'
#
class Joosy.Resources.Scalar extends Joosy.Module

  @include Joosy.Modules.Events
  @extend Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'
  @registerPlainFilters 'beforeChange'

  #
  # Instantiates a new instance
  #
  @build: ->
    new @ arguments...

  #
  # Internal helper for {Joosy.Modules.Resources.Function}
  #
  __call: ->
    if arguments.length > 0
      @set arguments[0]
    else
      @get()

  #
  # Accepts a value to encapsulate
  #
  constructor: (value) ->
    @load value

  #
  # Replaces the value with given (applies beforeLoad)
  #
  # @example
  #   data = Joosy.Resources.Scalar.build 1
  #   data.load 2
  #   data                                          # 2
  #
  load: (value) ->
    @value = @__applyBeforeLoads(value)
    @trigger 'changed', @__applyBeforeChanges()
    @value

  #
  # Gets current value
  #
  get: ->
    @value

  #
  # Replaces the value with given (doesn't apply beforeLoad)
  #
  # @param [Mixed] value              The value to set
  # @param [Object] options
  #
  # @option options [Boolean] silent       Suppresses modification trigger
  #
  # @see Joosy.Resources.Scalar.load
  #
  set: (@value, options={}) ->
    @trigger 'changed', @__applyBeforeChanges() unless options.silent

  #
  # JS helper converting object to its internal value during basic operations
  #
  # @nodoc
  #
  valueOf: ->
    @value.valueOf()

  #
  # String representation
  #
  # @nodoc
  #
  toString: ->
    @value.toString()

# AMD wrapper
if define?.amd?
  define 'joosy/resources/scalar', -> Joosy.Resources.Scalar