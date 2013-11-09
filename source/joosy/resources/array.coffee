#
# The array structure with the support of dynamic rendering
#
# @include Joosy.Modules.Events
# @extend  Joosy.Modules.Filters
#
# @example
#   data = Joosy.Resources.Array.build 1, 2, 3
#   data.get(0)                                     # 1
#   data.set(0, 5)                                  # triggers 'changed'
#   data.push(4)                                    # triggers 'changed'
#   data.load(7, 8, 9)                              # triggers 'changed'
#
class Joosy.Resources.Array extends Array
  Joosy.Module.merge @, Joosy.Module

  @include Joosy.Modules.Events
  @extend Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  #
  # Instantiates a new array
  #
  @build: ->
    new @ arguments...

  #
  # Accepts numerous parameters (corresponding to array members)
  # 
  constructor: ->
    @__fillData arguments, false

  #
  # Replaces all the values with given
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.load 1, 2, 3
  #
  load: ->
    @__fillData arguments

  #
  # Gets element by its index
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.get(0)                                   # 1
  #
  get: (index) ->
    @[index]

  #
  # Sets element by its index
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.set(0, 2)                                   # 2
  #   data                                             # [2, 2, 3]
  #
  set: (index, value) ->
    @[index] = value
    @trigger 'changed'
    value

  #
  # Pushes element to the end of array
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.push(4)                                  # 4
  #   data                                          # [1, 2, 3, 4]
  #
  push: ->
    result = super
    @trigger 'changed'
    result

  #
  # Pops element of the end of array
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.pop()                                    # 3
  #   data                                          # [1, 2]
  #
  pop: ->
    result = super
    @trigger 'changed'
    result

  #
  # Shits element of the beginning of array
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.shift()                                  # 1
  #   data                                          # [2, 3]
  #
  shift: ->
    result = super
    @trigger 'changed'
    result

  #
  # Adds element of the beginning of array
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.unshift(0)                               # 4
  #   data                                          # [0, 1, 2, 3]
  #
  unshift: ->
    result = super
    @trigger 'changed'
    result

  #
  # Changes the content of an array, adding new elements while removing old elements.
  #
  # @example
  #   data = Joosy.Resources.Array.build 1, 2, 3
  #   data.splice(0, 2, 6)                          # 2
  #   data                                          # [6, 3]
  #
  splice: ->
    result = super
    @trigger 'changed'
    result

  #
  # Prepares data for internal storage
  #
  # @private
  #
  __fillData: (data, notify=true) ->
    data = @slice.call(data, 0)

    @splice 0, @length if @length > 0
    @push entry for entry in @__applyBeforeLoads(data)

    @trigger 'changed' if notify

    null

# AMD wrapper
if define?.amd?
  define 'joosy/resources/array', -> Joosy.Resources.Array