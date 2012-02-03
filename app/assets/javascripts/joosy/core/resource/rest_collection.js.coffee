class Joosy.Resource.RESTCollection extends Joosy.Resource.GenericCollection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  pages: Object.extended()

  constructor: (@model, params={}) ->
    @params = Object.extended params

  reset: (entities, notify=true) ->
    super entities, false
    @pages = Object.extended 1: @data
    
    if notify
      @trigger 'changed'
    this

  # Clears the storage and gets new data from server
  fetch: (callback, options) ->
    @__fetch @params, options, (data) =>
      @reset data, false
      callback? this
      @trigger 'changed'
    this

  # Returns the subset for requested page. Requests with &page=x if not found localy.
  page: (number, callback, options) ->
    if @pages[number]?
      @reset @pages[number], false
      callback? @pages[number]
      @trigger 'changed'
      return @

    @__fetch @params, options, (data) =>
      @reset data, false
      @pages[number] = data
      callback? @data
      @trigger 'changed'
    this
    
  __fetch: (urlOptions, ajaxOptions, callback) ->
    @model.__ajax 'get', @model.__buildSource(params: @params.merge(urlOptions)), ajaxOptions, (data) ->
      callback(data)
