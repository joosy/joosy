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
  load: (entities, notify=true) ->
    super entities, false
    @trigger 'changed' if notify
    this

  #
  # Clears the storage and gets new data from server.
  #
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
  #
  # @return [Joosy.Resource.RESTCollection]   Returns self.
  #
  fetch: (options, callback=nil) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @model.__query @model.collectionPath(options), 'GET', options.params, (data) =>
      @load data
      callback(collection)