#
# Collection of Resources with REST-fetching capabilities
#
# Generally you should not use RESTCollection directly. It will be
# automatically created by Joosy.Resource.REST#find.
#
# Example:
#   class R extends Joosy.Resource.REST
#     @entity 'r'
#
#   collection = new Joosy.Resource.RESTCollection(R, {color: 'green'})
#
#   collection.fetch()
#   collection.page 2
#
#   collection.params = {color: 'red', sort: 'date'}
#   collection.fetch()
#
class Joosy.Resource.RESTCollection extends Joosy.Resource.Collection
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  #
  # Hash containing the cache for pages of raw data
  # Keys are pages numbers, values are stored AJAX response
  #
  pages: Object.extended()

  #
  # @param [Class] model      Resource class this collection will handle
  # @param [Object] params    Additional GET-parameters to supply when fetching
  #
  constructor: (model, params={}) ->
    super model
    @params = Object.extended params

  #
  # Clears the storage and attempts to import given JSON
  #
  # @param [Object] entities    Entities to import
  #
  reset: (entities, notify=true) ->
    super entities, false
    if notify
      @trigger 'changed'
    this

  #
  # Clears the storage and gets new data from server
  #
  # @param [Function|Object] options                AJAX options.
  #   Will be considered as a success callback if function given
  #
  fetch: (options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
    
    @__fetch @params, options, (data) =>
      @reset data, false
      callback? this
      @trigger 'changed'
    this

  #
  # Returns the subset for requested page. Requests with &page=x if not found localy.
  #
  # @param [Integer] number               Index of page
  # @param [Function|Object] options      AJAX options.
  #   Will be considered as a success callback if function given
  #
  page: (number, options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
    
    @__fetch Joosy.Module.merge({page: number}, @params), options, (data) =>
      @reset data, false
      callback? @data
      @trigger 'changed'
    this
    
  #
  # Requests the REST collection URL with POST or any method given in options.type
  #
  # @param [String] ending            Collection url (like 'foo' or 'foo/bar')
  # @param [Function|Object] options  AJAX options.
  #   Will be considered as a success callback if function given
  #
  request: (ending, options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
      
    if options.method || options.type
      type = options.method || options.type
    else
      type = 'post'
    
    @model.__ajax type, @model.__buildSource(extension: ending), options, callback
    
  #
  # Does AJAX request
  #
  # @param [Object] urlOptions      GET-params for request
  # @param [Object] ajaxOptions     AJAX options to pass with request
  # @param [Function] callback
  #
  __fetch: (urlOptions, ajaxOptions, callback) ->
    @model.__ajax 'get', @model.__buildSource(params: @params.merge(urlOptions)), ajaxOptions, (data) ->
      callback(data)