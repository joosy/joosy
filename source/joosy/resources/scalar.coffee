class Joosy.Resources.Scalar extends Joosy.Function

  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  constructor: (value) ->
    return super ->
      @value = value

  get: ->
    @value

  set: ->
    @load arguments...

  load: (value) ->
    @value = @__applyBeforeLoads(value)
    @trigger 'changed'
    @value

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