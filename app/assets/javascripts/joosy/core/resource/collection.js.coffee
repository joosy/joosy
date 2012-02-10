#
# Basic collection of Resources
# Turns JSON array into array of Resources and manages them
#
# Generally you should not use Collection directly. It will be
# automatically created by things like Joosy.Resource.Generic#map 
# or Joosy.Resource.REST#find.
#
# Example:
#   class R extends Joosy.Resource.Generic
#     @entity 'r'
#
#   collection = new Joosy.Resource.Collection(R)
#
#   collection.reset [{foo: 'bar'}, {foo: 'baz'}]
#   collection.each (resource) ->
#     resource('foo')
#
class Joosy.Resource.Collection extends Joosy.Module
  @include Joosy.Modules.Events
  
  #
  # Allows to modify data before it gets stored
  #
  # @param [Function] action    `(Object) -> Object` to call
  #
  @beforeLoad: (action) -> @::__beforeLoad = action
  
  #
  # Modelized data storage
  #
  data: []
  
  #
  # @param [Class] model    Resource class this collection will handle
  #
  constructor: (@model) ->
  
  #
  # Clears the storage and attempts to import given JSON
  #
  # @param [Object] entities    Entities to import
  # @param [Boolean] notify     Indicates whether to trigger 'changed' event
  #
  reset: (entities, notify=true) ->
    if @__beforeLoad?
      entities = @__beforeLoad entities

    @data = @modelize entities
    
    if notify
      @trigger 'changed'
    this
  
  #
  # Turns Objects array into array of Resources
  #
  # @param [Array] collection     Array of Objects
  #
  modelize: (collection) ->
    root = @model::__entityName.pluralize()

    if collection not instanceof Array
      collection = collection?[root.camelize(false)]

      if collection not instanceof Array
        throw new Error "Can not read incoming JSON" 

    collection.map (x) =>
      @model.create x
      
  #
  # Calls callback for each Resource inside Collection
  #
  # @param [Function] callback
  #
  each: (callback) ->
    @data.each callback
    
  #
  # Gets first resource matching description (see Sugar.js Array#find)
  #
  # @param [Function] description       Callback matcher
  #
  find: (description) ->
    @data.find description
  
  #
  # Gets resource by id
  #
  # @param [Integer] id       Id to find
  #
  findById: (id) ->
    @data.find (x) -> x('id').toString() == id.toString()
  
  #
  # Gets resource by its index inside collection
  #
  # @param [Integer] i    Index
  #
  at: (i) ->
    @data[i]

  #
  # Removes resource from collection by its index or by === comparison
  #
  # @param [Integer] target     Index
  # @param [Resource] target    Resource by itself
  # @param [Boolean] notify     Indicates whether to trigger 'changed' event
  #
  remove: (target, notify=true) ->
    if Object.isNumber target
      index = target
    else
      index = @data.indexOf target
    if index >= 0
      result = @data.splice(index, 1)[0]
      if notify
        @trigger 'changed'
    result

  #
  # Adds resource to collection to given index or to the end
  #
  # @param [Resource] element       Resource to add
  # @param [Integer] index          Index to add to. If omited will be pushed to the end
  # @param [Boolean] notify         Indicates whether to trigger 'changed' event
  #
  add: (element, index=false, notify=true) ->
    if index
      @data.splice index, 0, element
    else
      @data.push element
      
    if notify
      @trigger 'changed'
    element