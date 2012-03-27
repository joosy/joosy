#
# Collection of Resources with REST-fetching capabilities.
#
# @note Generally you should not use RESTCollection directly. It will be
#   automatically created by Joosy.Resource.REST#find.
#
# @example Basic samples
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
  # Hash containing the cache for pages of raw data.
  # Keys are pages numbers, values are stored AJAX response.
  #
  pages: Object.extended()

  #
  # @param [Class] model      Resource class this collection will handle
  # @param [Hash] params      Additional parameters that will be added to all REST requests.
  #
  constructor: (model, params={}) ->
    super model
    @params = Object.extended params

  #
  # Clears the storage and attempts to import given array
  #
  # @param [Array, Hash] entities     Array of entities to import.
  #   If hash was given will seek for moodel name camelized and pluralized.
  # @param [Boolean] notify           Indicates whether to trigger 'changed' event
  #
  # @return [Joosy.Resource.RESTCollection]   Returns self.
  #
  reset: (entities, notify=true) ->
    super entities, false
    if notify
      @trigger 'changed'
    this

  #
  # Clears the storage and gets new data from server.
  #
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
  #
  # @return [Joosy.Resource.RESTCollection]   Returns self.
  #
  fetch: (options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
    
    @__fetch {}, options, (data) =>
      @reset data, false
      callback? this
      @trigger 'changed'
    this

  #
  # Returns the subset for requested page: requests with &page=x.
  #
  # @param [Integer] number             Index of page
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
  #
  # @return [Joosy.Resource.RESTCollection]   Returns self.
  #
  page: (number, options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
    
    @__fetch {page: number}, options, (data) =>
      @reset data, false
      callback? @data
      @trigger 'changed'
    this
    
  #
  # Requests the REST collection URL with POST or any method given in options.type.
  #
  # @param [String] ending              Collection url (like 'foo' or 'foo/bar')
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
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
  # Internal AJAX request implementation.
  #
  # @param [Hash] urlOptions      GET-params for request
  # @param [Hash] ajaxOptions     AJAX options to pass with request
  # @param [Function] callback
  #
  __fetch: (urlOptions, ajaxOptions, callback) ->
    @model.__ajax 'get', @model.__buildSource(params: Object.extended({}).merge(@params).merge(urlOptions)), ajaxOptions, (data) ->
      callback(data)