#
# Basic data wrapper with triggering and entity name binding
#
# @example Basic usage
#   class R extends Joosy.Resources.Base
#     @entity 'r'
#
#     @beforeLoad (data) ->
#       data.real = true
#
#   r = R.build {r: {foo: {bar: 'baz'}}}
#
#   r('foo')                  # {baz: 'baz'}
#   r('real')                 # true
#   r('foo.bar')              # baz
#   r('foo.bar', 'fluffy')    # triggers 'changed'
#
# @include Joosy.Modules.Log
# @include Joosy.Modules.Events
#
class Joosy.Resources.Base extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Default primary key field 'id'
  #
  __primaryKey: 'id'

  #
  # Clears the identity map cache. Recomended to be called during layout switch to
  # ensure correct garbage collection.
  #
  @resetIdentity: ->
    Joosy.Resources.Base.identity = {}

  #
  # Allows to modify data before it gets stored.
  # You can define several beforeLoad filters that will be chained.
  #
  # @param [Function] action    `(Object) -> Object` to call
  #
  @beforeLoad: (action) ->
    unless @::hasOwnProperty '__beforeLoads'
      @::__beforeLoads = [].concat @.__super__.__beforeLoads || []
    @::__beforeLoads.push action

  #
  # Sets the field containing primary key.
  #
  # @note It has no direct use inside the REST resource itself and can be omited.
  #   But it usually should not since we have plans on adding some kind of Identity Map to Joosy.
  #
  # @param [String] primary     Name of the field
  #
  @primaryKey: (primaryKey) ->
    @::__primaryKey = primaryKey

  #
  # Sets the entity text name:
  #   required to do some magic like skipping the root node.
  #
  # @param [String] name    Singular name of resource
  #
  @entity: (name) ->
    @::__entityName = name

  #
  # Sets the collection to use
  #
  # @note By default will try to seek for `EntityNamesCollection`.
  #   Will fallback to {Joosy.Resources.Collection}
  #
  # @param [Class] klass       Class to assign as collection
  #
  @collection: (klass) -> @::__collection = -> klass

  #
  # Implements {Joosy.Resources.Base.collection} default behavior.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resources.Collection

  #
  # Dynamically creates collection of inline resources.
  #
  # Inline resources share the instance with direct data and therefore can be used
  #   to handle inline changes with triggers and all that resources stuff
  #
  # @example Basic usage
  #   class Zombie extends Joosy.Resources.Base
  #     @entity 'zombie'
  #   class Puppy extends Joosy.Resources.Base
  #     @entity 'puppy'
  #     @map 'zombies'
  #
  #   p = Puppy.build {zombies: [{foo: 'bar'}]}
  #
  #   p('zombies')            # Direct access: [{foo: 'bar'}]
  #   p.zombies               # Wrapped Collection of Zombie instances
  #   p.zombies.at(0)('foo')  # bar
  #
  # @param [String] name    Pluralized name of property to define
  # @param [Class] klass    Resource class to instantiate
  #
  @map: (name, klass=false) ->
    unless klass
      klass = window[name.singularize().camelize()]

    if !klass
      throw new Error "#{Joosy.Module.__className @}> class can not be detected for '#{name}' mapping"

    @beforeLoad (data) ->
      klass = klass() unless Joosy.Module.hasAncestor(klass, Joosy.Resources.Base)

      @__map(data, name, klass)

  #
  # Wraps instance of resource inside shim-function allowing to track
  # data changes. See class example
  #
  # @return [Joosy.Resources.Base]
  #
  @build: (data={}) ->
    klass = @::__entityName

    Joosy.Resources.Base.identity ||= {}
    Joosy.Resources.Base.identity[klass] ||= {}

    shim = @__makeShim(@::)

    if Object.isNumber(data) || Object.isString(data)
      id   = data
      data = {}
      data[shim.__primaryKey] = id

    if Joosy.Resources.Base.identity
      id = data[shim.__primaryKey]

      if id? && Joosy.Resources.Base.identity[klass][id]
        shim = Joosy.Resources.Base.identity[klass][id]
        shim.load data
      else
        Joosy.Resources.Base.identity[klass][id] = shim
        @apply shim, [data]
    else
      @apply shim, [data]

    shim

  #
  # Makes base shim-function for making instances through build or making instance clones
  #
  # @param [Object] proto         Any function or object whose properties will be inherited by a new function
  #
  @__makeShim: (proto) ->
    shim = ->
      shim.__call.apply shim, arguments

    if shim.__proto__
      shim.__proto__ = proto
    else
      for key, value of proto
        shim[key] = value

    shim.constructor = @

    shim

  #
  # Should NOT be called directly, use {::build} instead
  #
  # @private
  # @param [Object] data      Data to store
  #
  constructor: (data={}) ->
    @__fillData data, false

  id: ->
    @data?[@__primaryKey]

  knownAttributes: ->
    Object.keys @data

  #
  # Set the resource data manually
  #
  # @param [Object] data      Data to store
  #
  # @return [Joosy.Resources.Base]      Returns self
  #
  load: (data, clear=false) ->
    @data = {} if clear
    @__fillData data
    return this

  #
  # Getter for wrapped data
  #
  # @param [String] path    Attribute name to get. Can contain dots to get inline Objects values
  # @return [mixed]
  #
  __get: (path) ->
    target = @__callTarget path, true

    if !target
      return undefined
    else if target[0] instanceof Joosy.Resources.Base
      return target[0](target[1])
    else
      return target[0][target[1]]

  #
  # Setter for wrapped data, triggers `changed` event.
  #
  # @param [String] path    Attribute name to set. Can contain dots to get inline Objects values
  # @param [mixed] value    Value to set
  #
  __set: (path, value) ->
    target = @__callTarget path

    if target[0] instanceof Joosy.Resources.Base
      target[0](target[1], value)
    else
      target[0][target[1]] = value

    @trigger 'changed'
    null

  #
  # Locates the actual instance of attribute path `foo.bar` from get/set
  #
  # @param [String] path    Path to the attribute (`foo.bar`)
  # @param [Boolean] safe   Indicates whether nested hashes should not be automatically created when they don't exist
  # @return [Array]         Instance of object containing last step of path and keyword for required field
  #
  __callTarget: (path, safe=false) ->
    if path.has(/\./) && !@data[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @data

      for part in path
        return false if safe && !target[part]?

        target[part] ||= {}
        if target instanceof Joosy.Resources.Base
          target = target(part)
        else
          target = target[part]

      [target, keyword]
    else
      [@data, path]

  #
  # Wrapper for {Joosy.Resources.Base.build} magic
  #
  __call: (path, value) ->
    if arguments.length > 1
      @__set path, value
    else
      @__get path

  #
  # Defines how exactly prepared data should be saved
  #
  # @param [Object] data    Raw data to store
  #
  __fillData: (data, notify=true) ->
    @raw  = data
    @data = {} unless @hasOwnProperty 'data'

    Joosy.Module.merge @data, @__prepareData(data)

    @trigger 'changed' if notify

    null

  #
  # Prepares raw data: cuts the root node if it exists, runs before filters
  #
  # @param [Hash] data    Raw data to prepare
  # @return [Hash]
  #
  __prepareData: (data) ->
    if Object.isObject(data) && Object.keys(data).length == 1 && @__entityName
      name = @__entityName.camelize(false)
      data = data[name] if data[name]

    if @__beforeLoads?
      data = bl.call(this, data) for bl in @__beforeLoads

    data

  __map: (data, name, klass) ->
    if Object.isArray data[name]
      entry = new (klass::__collection()) klass
      entry.load data[name]
      data[name] = entry
    else if Object.isObject data[name]
      data[name] = klass.build data[name]
    data
