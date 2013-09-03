#= require joosy/modules/resources/cacher

class Joosy.Resources.Scalar extends Joosy.Function

  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  constructor: (value) ->
    return super ->
      @load value

  get: ->
    @value

  set: (@value) ->
    @trigger 'changed'

  load: (value) ->
    @value = @__applyBeforeLoads(value)
    @trigger 'changed'
    @value

  clone: (callback) ->
    new @constructor @value

  __call: ->
    if arguments.length > 0
      @set arguments[0]
    else
      @get()

  valueOf: ->
    @value.valueOf()

  toString: ->
    @value.toString()

# AMD wrapper
if define?.amd?
  define 'joosy/resources/scalar', -> Joosy.Resources.Scalar