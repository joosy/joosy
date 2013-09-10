class Joosy.Resources.Scalar extends Joosy.Module

  @extend  Joosy.Modules.Function
  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  constructor: (value) ->
    @load value

  load: (value) ->
    @value = @__applyBeforeLoads(value)
    @trigger 'changed'
    @value

  __call: ->
    if arguments.length > 0
      @__set arguments[0]
    else
      @__get()

  __get: ->
    @value

  __set: (@value) ->
    @trigger 'changed'

  valueOf: ->
    @value.valueOf()

  toString: ->
    @value.toString()

# AMD wrapper
if define?.amd?
  define 'joosy/resources/scalar', -> Joosy.Resources.Scalar