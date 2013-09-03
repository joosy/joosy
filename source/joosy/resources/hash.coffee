class Joosy.Resources.Hash extends Joosy.Function

  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  constructor: (data={}) ->
    return super ->
      @__fillData data, false

  get: (path) ->
    [instance, property] = @__callTarget path, true

    return undefined unless instance
      
    if instance instanceof Joosy.Resources.Hash
      instance property
    else
      instance[property]

  set: (path, value) ->
    [instance, property] = @__callTarget path

    if instance instanceof Joosy.Resources.Hash
      instance(property, value)
    else
      instance[property] = value

    @trigger 'changed'
    value

  load: (data) ->
    @__fillData data
    @

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

        target = if target instanceof Joosy.Resources.Hash
          target(part)
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
    JSON.stringify(@data)

# AMD wrapper
if define?.amd?
  define 'joosy/resources/hash', -> Joosy.Resources.Hash