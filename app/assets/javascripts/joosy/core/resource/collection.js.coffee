#
# Basic collection of Resources
# Turns JSON array into array of Resources and manages them
#
# Generally you should not use Collection directly. It will be
# automatically created by things like Resource.Generic#map or
# Resource.REST#find.
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
      collection = collection?[root]

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
  # Gets resource by it's index inside collection
  #
  # @param [Integer] i    Index
  #
  at: (i) ->
    @data[i]
