class Joosy.Resource.GenericCollection extends Joosy.Module
  @include Joosy.Modules.Events
  
  data:  []
  
  constructor: (@model) ->
  
  # Clears the storage and attempts to import given JSON
  reset: (entities) ->
    @data  = @modelize entities
    @pages = Object.extended().merge { 1: @data }

    this
    
  modelize: (collection) ->
    root = @model.entityName().pluralize()

    if collection not instanceof Array
      collection = collection?[root]

      if collection not instanceof Array
        throw new Error "Can not read incoming JSON" 

    collection.map (x) =>
      @model.create x