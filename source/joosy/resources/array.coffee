class Joosy.Resources.Array extends Array

  Joosy.Module.include.call @, Joosy.Modules.Events
  Joosy.Module.include.call @, Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  constructor: ->
    @__fillData arguments, false

  get: (index) ->
    @[index]

  set: (index, value) ->
    @[index] = value
    @trigger 'changed'
    value

  load: ->
    @__fillData arguments

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

  __fillData: (data, notify=true) ->
    data = if data[0] instanceof Array
      data[0]
    else
      @slice.call(data, 0)

    @splice 0, @length if @length > 0
    @push entry for entry in @__applyBeforeLoads(data)

    @trigger 'changed' if notify

    null

# AMD wrapper
if define?.amd?
  define 'joosy/resources/array', -> Joosy.Resources.Array