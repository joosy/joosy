class Joosy.Resources.Array extends Array

  Joosy.Module.include.call @, Joosy.Modules.Events

  constructor: ->
    @push entry for entry in @slice.call(arguments, 0)

  get: (index) ->
    @[index]

  set: (index, value) ->
    @[index] = value
    @trigger 'changed'
    @length

  push: ->
    result = super
    @trigger 'changed'
    result

  pop: ->
    result = super
    @trigger 'changed'
    result

  shift: ->
    result = super
    @trigger 'changed'
    result

  unshift: ->
    result = super
    @trigger 'changed'
    result

  splice: ->
    result = super
    @trigger 'changed'
    result

# AMD wrapper
if define?.amd?
  define 'joosy/resources/array', -> Joosy.Resources.Array