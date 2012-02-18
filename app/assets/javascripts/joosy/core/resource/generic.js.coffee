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
#   r = R.create {r: {foo: {bar: 'baz'}}}
#   
#   r('foo')                  # {baz: 'baz'}
#   r('real')                 # true
#   r('foo.bar')              # baz
#   r('foo.bar', 'fluffy')    # triggers 'changed'
#
class Joosy.Resource.Generic extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Sets the data source description (which is NOT required)
  # @note This has no use in Generic but is required in any descendant
  # 
  # @param [mixed] Source can be any type including lambda.
  #   If lambda is given resource will not expect direct {::create} calls
  #   You'll have to prepare descendant with {::at} first.
  #
  # @example Simple case
  #   Class Y extends Joosy.Resource.Generic
  #     @source 'fluffies'
  #   
  #   r = Y.create {}
  #
  # @example Case with lambda
  #   class R extends Joosy.Resource.Generic
  #     @source -> (path) "/"+path
  #   
  #   r = R.create {}                 # will raise exception
  #   r = R.at('foo/bar').create {}   # will work as expected
  #
  @source: (source) -> @__source = source
  
  #
  # Creates the proxy of current resource with proper {::source} value
  #
  # @note Should be used together with lambda source (see {::source} for example)
  #
  @at: ->
    if !Object.isFunction @__source
      throw new Error "#{Joosy.Module.__className @}> should be created directly (without `at')"

    #
    # Class inheritance used to create proxy
    #
    # @private
    #
    class clone extends this
    clone.__source = @__source arguments...
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
  # @param [Object] klass       Class to assign as collection
  #
  @collection: (klass) -> @::__collection = -> klass
  
  #
  # Implements {::collection} default behavior.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.Collection
  
  #
  # Allows to modify data before it gets stored.
  # You can define several beforeLoad filters.
  #
  # @param [Function] action    `(Object) -> Object` to call
  #
  @beforeLoad: (action) ->
    unless @::hasOwnProperty '__beforeLoads'
      @::__beforeLoads = [].concat @.__super__.__beforeLoads || []
    @::__beforeLoads.push action

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
  #     @maps 'zombies'
  #   
  #   p = Puppy.create {zombies: [{foo: 'bar'}]}
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
      @[name] = new (klass::__collection()) klass
      if Object.isArray data[name]
        @[name].reset data[name]
      data

  #
  # Wraps instance of resource inside shim-function allowing to track
  # data changes. See class example
  #
  # @return [Joosy.Resource.Generic]
  #
  @create: ->    
    shim = ->
      shim.__call.apply shim, arguments

    if shim.__proto__
      shim.__proto__ = @prototype
    else
      for key, value of @prototype
        shim[key] = value
        
    shim.constructor = @
    
    @apply shim, arguments

    shim

  #
  # Should NOT be called directly, use {#create} instead
  #
  # @abstract
  # @param [Object] data      Data to store
  #
  constructor: (data) ->
    @__fillData data, false
    
  #
  # Set the resource data manually
  #
  # @param [Object] data      Data to store
  #
  reset: (data) ->
    @__fillData data
  
  #
  # Getter for wrapped data
  #
  # @param [String] path    Attribute name to get. Can contain dots to get inline Objects values
  # @return [mixed]
  #
  get: (path) ->
    target = @__callTarget path
    target[0][target[1]]

  #
  # Setter for wrapped data, triggers `changed` event.
  #
  # @param [String] path    Attribute name to set. Can contain dots to get inline Objects values
  # @param [mixed] value    Value to set
  #
  set: (path, value) ->
    target = @__callTarget path
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
    if path.has(/\./) && !@e[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @e
      
      for part in path
        target[part] ||= {}
        target = target[part]

      [target, keyword]
    else
      [@e, path]

  #
  # Wrapper for {#create} magic
  #
  __call: (path, value) ->
    if arguments.length > 1
      @set path, value
    else
      @get path

  #
  # Defines how exactly prepared data should be saved
  #
  # @param [Object] data    Raw data to store
  #
  __fillData: (data, notify=true) ->
    @e = @__prepareData data
    
    if notify
      @trigger 'changed'

    null

  #
  # Prepares raw data: cuts the root node if it exists, runs before filters
  #
  # @param [Object] data    Raw data to prepare
  # @return [Object]
  #
  __prepareData: (data) ->    
    if Object.isObject(data) && Object.keys(data).length == 1 && @__entityName
      name = @__entityName.camelize(false)
      data = data[name] if data[name]

    if @__beforeLoads?
      data = bl.call(this, data) for bl in @__beforeLoads
      
    data