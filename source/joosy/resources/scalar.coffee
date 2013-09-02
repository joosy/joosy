class Joosy.Resources.Scalar extends Joosy.Function

  @include Joosy.Modules.Events

  constructor: (value) ->
    return super ->
      @value = value

  __call: ->
    if arguments.length > 0
      @set arguments[0]
    else
      @get()

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