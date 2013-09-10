#= require joosy/modules/function

class Joosy.Resources.Hash extends Joosy.Module

  @extend  Joosy.Modules.Function
  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  constructor: (data={}) ->
    @__fillData data, false

  load: (data) ->
    @__fillData data
    @

  __get: (path) ->
    [instance, property] = @__callTarget path, true

    return undefined unless instance

    if instance.__get?
      instance.__get(property)
    else
      instance[property]

  __set: (path, value) ->
    [instance, property] = @__callTarget path

    if instance.__set?
      instance.__set(property, value)
    else
      instance[property] = value

    @trigger 'changed'
    value

  __call: (path, value) ->
    if arguments.length > 1
      @__set path, value
    else
      @__get path

  #
  # Locates the actual instance of attribute path `foo.bar` from get/set
  #
  # @param [String] path    Path to the attribute (`foo.bar`)
  # @param [Boolean] safe   Indicates whether nested hashes should not be automatically created when they don't exist
  # @return [Array]         Instance of object containing last step of path and keyword for required field
  #
  __callTarget: (path, safe=false) ->
    if path.indexOf('.') != -1 && !@data[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @data

      for part in path
        return false if safe && !target[part]?

        target[part] ?= {}

        target = if target.__get
          target.__get(part)
        else
          target[part]

      [target, keyword]
    else
      [@data, path]

  #
  # Defines how exactly prepared data should be saved
  #
  # @param [Object] data    Raw data to store
  #
  __fillData: (data, notify=true) ->
    @data = @__applyBeforeLoads data
    @trigger 'changed' if notify
    null

  toString: ->
    "Hash: #{JSON.stringify(@data)}"

# AMD wrapper
if define?.amd?
  define 'joosy/resources/hash', -> Joosy.Resources.Hash