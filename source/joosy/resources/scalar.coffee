class Joosy.Resources.Scalar extends Joosy.Module

  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  @build: ->
    new @ arguments...

  __call: ->
    if arguments.length > 0
      @set arguments[0]
    else
      @get()

  constructor: (value) ->
    @load value

  load: (value) ->
    @value = @__applyBeforeLoads(value)
    @trigger 'changed'
    @value

  get: ->
    @value

  set: (@value) ->
    @trigger 'changed'

  valueOf: ->
    @value.valueOf()

  toString: ->
    @value.toString()

# AMD wrapper
if define?.amd?
  define 'joosy/resources/scalar', -> Joosy.Resources.Scalar