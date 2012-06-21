#
# Basic data wrapper with triggering and entity name binding
#
# @example Basic usage
#   class R extends Joosy.Resource.Generic
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
class Joosy.Resource.Generic extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Default primary key field 'id'
  #
  __primaryKey: 'id'

  __source: false

  #
  # Clears the identity map cache. Recomended to be called during layout switch to 
  # ensure correct garbage collection.
  #
  @resetIdentity: ->
    Joosy.Resource.Generic.identity = {}

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
  @primaryKey: (primaryKey) -> @::__primaryKey = primaryKey

  @source: (location) ->
    @__source = location

  #
  # Creates the proxy of current resource binded as a child of given entity
  #
  @at: (entity) ->
    #
    # Class inheritance used to create proxy
    #
    # @private
    #
    class clone extends this

    if entity instanceof Joosy.Resource.Generic
      clone.__source  = entity.memberPath() 
      clone.__source += '/' + @::__entityName.pluralize() if @::__entityName
    else
      clone.__source = entity

    clone

  #
  # Sets the entity text name:
  #   required to do some magic like skipping the root node.
  #
  # @param [String] name    Singular name of resource
  #
  @entity: (name) -> @::__entityName = name
  
  #
  # Sets the collection to use
  #
  # @note By default will try to seek for `EntityNamesCollection`.
  #   Will fallback to {Joosy.Resource.Collection}
  #
  # @param [Class] klass       Class to assign as collection
  #
  @collection: (klass) -> @::__collection = -> klass
  
  #
  # Implements {Joosy.Resource.Generic.collection} default behavior.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.Collection

  #
  # Dynamically creates collection of inline resources.
  #
  # Inline resources share the instance with direct data and therefore can be used
  #   to handle inline changes with triggers and all that resources stuff
  #
  # @example Basic usage
  #   class Zombie extends Joosy.Resource.Generic
  #     @entity 'zombie'
  #   class Puppy extends Joosy.Resource.Generic
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
      klass = klass() unless Joosy.Module.hasAncestor(klass, Joosy.Resource.Generic)
        
      @__map(data, name, klass)

  #
  # Wraps instance of resource inside shim-function allowing to track
  # data changes. See class example
  #
  # @return [Joosy.Resource.Generic]
  #
  @build: (data={}) ->
    klass = @::__entityName

    Joosy.Resource.Generic.identity ||= {}
    Joosy.Resource.Generic.identity[klass] ||= {}

    shim = ->
      shim.__call.apply shim, arguments

    if shim.__proto__
      shim.__proto__ = @prototype
    else
      for key, value of @prototype
        shim[key] = value
        
    shim.constructor = @

    if Object.isNumber(data) || Object.isString(data)
      id   = data
      data = {}
      data[shim.__primaryKey] = id
    
    if Joosy.Application.identity
      id = data[shim.__primaryKey]

      if id? && Joosy.Resource.Generic.identity[klass][id]
        shim = Joosy.Resource.Generic.identity[klass][id]
        shim.load data
      else
        @apply shim, [data]
        Joosy.Resource.Generic.identity[klass][id] = shim
    else
      @apply shim, [data]

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
    @data[@__primaryKey]

  knownAttributes: ->
    @data.keys()

  #
  # Set the resource data manually
  #
  # @param [Object] data      Data to store
  #
  # @return [Joosy.Resource.Generic]      Returns self
  #
  load: (data) ->
    @__fillData data
    return this
  
  #
  # Getter for wrapped data
  #
  # @param [String] path    Attribute name to get. Can contain dots to get inline Objects values
  # @return [mixed]
  #
  __get: (path) ->
    target = @__callTarget path

    if target[0] instanceof Joosy.Resource.Generic
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

    if target[0] instanceof Joosy.Resource.Generic
      target[0](target[1], value)
    else
      target[0][target[1]] = value
    
    @trigger 'changed'
    null

  #
  # Locates the actual instance of attribute path `foo.bar` from get/set
  #
  # @param [String] path    Path to the attribute (`foo.bar`)
  # @return [Array]         Instance of object containing last step of path and keyword for required field
  #
  __callTarget: (path) ->
    if path.has(/\./) && !@data[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @data
      
      for part in path
        target[part] ||= {}
        if target instanceof Joosy.Resource.Generic
          target = target(part)
        else
          target = target[part]

      [target, keyword]
    else
      [@data, path]

  #
  # Wrapper for {Joosy.Resource.Generic.build} magic
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