class Joosy.Resource.RESTCollection extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events
  
  data: []
  pages: Object.extended()
  
  constructor: (@model, params={}) -> @params = Object.extended(params)
  
  # Clears the storage and atempts to import given JSON
  reset: (entities) ->
    @data = data = entities.map (x) => new @model(x)
    @pages = Object.extended().merge 1: data
    @

  # Clears the storage and gets new data from server
  fetch: (callback=false) ->
    @model.__ajax 'get', @model.__buildSource(params: @params), (data) =>
      @reset(data)
      callback?(@)
    @

  # Returns the subset for requested page. Requests with &page=x if not found localy.
  page: (number, callback=false) ->
    if @pages[number]?
      callback?(@pages[number])
      return @ 
    
    @model.__ajax 'get', @model.__buildSource(params: @params.merge(page: number)), (data) =>
      @pages[number] = data.map (x) => new @model(x)
      
      @data = []
      @pages.keys().sort().each (x) => @data.add @pages[x]
      
      callback?(@pages[number])
    @