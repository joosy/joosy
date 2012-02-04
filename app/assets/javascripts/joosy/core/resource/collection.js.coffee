class Joosy.Resource.Collection extends Joosy.Module
  @include Joosy.Modules.Events
  
  @beforeLoad: (action) -> @::__beforeLoad = action
  
  data: []
  
  constructor: (@model) ->
  
  # Clears the storage and attempts to import given JSON
  reset: (entities, notify=true) ->
    if @__beforeLoad?
      entities = @__beforeLoad entities

    @data = @modelize entities
    
    if notify
      @trigger 'changed'
    this
    
  modelize: (collection) ->
    root = @model::__entityName.pluralize()

    if collection not instanceof Array
      collection = collection?[root]

      if collection not instanceof Array
        throw new Error "Can not read incoming JSON" 

    collection.map (x) =>
      @model.create x
      
  each: (callback) ->
    @data.each callback
    
  at: (i) ->
    @data[i]
