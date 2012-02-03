class Joosy.Resource.RESTCollection extends Joosy.Resource.GenericCollection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  pages: Object.extended()

  constructor: (@model, params={}) ->
    @params = Object.extended params

  reset: (entities) ->
    super entities
    @pages = Object.extended 1: @data
    this

  # Clears the storage and gets new data from server
  fetch: (callback, options) ->
    @__fetch {}, options, (data) =>
      @reset data
      callback? this
    this

  # Returns the subset for requested page. Requests with &page=x if not found localy.
  page: (number, callback=false, options) ->
    if @pages[number]?
      @reset @pages[number]
      callback? @pages[number]
      return @

    @__fetch {}, options, (data) =>
      @reset data
      @pages[number] = data
      callback? @pages[number]
    this
    
  __fetch: (urlOptions, ajaxOptions, callback) ->
    @model.__ajax 'get', @model.__buildSource(params: @params.merge(urlOptions)), ajaxOptions, (data) ->
      callback(data)
