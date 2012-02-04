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
  constructor: (@model, params={}) ->
    @params = Object.extended params

  #
  # Clears the storage and attempts to import given JSON
  #
  # @param [Object] entities    Entities to import
  #
  reset: (entities, notify=true) ->
    super entities, false
    @pages = Object.extended 1: @data
    
    if notify
      @trigger 'changed'
    this

  #
  # Clears the storage and gets new data from server
  #
  # @param [Function] callback    `(RESTCollection) -> null` to call when data arrived
  #   Can be used to modify collection after fetch but before 'changed' trigger
  # @param [Object] options       AJAX options to pass with request
  #
  fetch: (callback, options) ->
    @__fetch @params, options, (data) =>
      @reset data, false
      callback? this
      @trigger 'changed'
    this

  #
  # Returns the subset for requested page. Requests with &page=x if not found localy.
  #
  # @param [Integer] number       Index of page
  # @param [Function] callback    `(RESTCollection) -> null` to call when data arrived
  #   Can be used to modify collection after fetch but before 'changed' trigger
  # @param [Object] options       AJAX options to pass with request
  #
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