class Joosy.Resources.Hash extends Joosy.Module

  @include Joosy.Modules.Events
  @extend Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  @build: ->
    new @ arguments...

  __call: (path, value) ->
    if arguments.length > 1
      @set path, value
    else
      @get path

  constructor: (data={}) ->
    @__fillData data, false

  load: (data) ->
    @__fillData data
    @

  get: (path) ->
    [instance, property] = @__callTarget path, true

    return undefined unless instance

    if instance.get
      instance.get(property)
    else
      instance[property]

  set: (path, value) ->
    [instance, property] = @__callTarget path

    if instance.set?
      instance.set(property, value)
    else
      instance[property] = value

    @trigger 'changed'
    value

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