class Joosy.Resources.Array extends Array

  Joosy.Module.merge @, Joosy.Module

  @include Joosy.Modules.Events
  @extend Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  @build: ->
    new @ arguments...

  constructor: ->
    @__fillData arguments, false

  load: ->
    @__fillData arguments

  get: (index) ->
    @[index]

  set: (index, value) ->
    @[index] = value
    @trigger 'changed'
    value

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
    data = @slice.call(data, 0)

    @splice 0, @length if @length > 0
    @push entry for entry in @__applyBeforeLoads(data)

    @trigger 'changed' if notify

    null

# AMD wrapper
if define?.amd?
  define 'joosy/resources/array', -> Joosy.Resources.Array