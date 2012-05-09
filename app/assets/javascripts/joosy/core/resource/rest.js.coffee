class Joosy.Resource.REST extends Joosy.Resource.Generic

  #
  # Implements `@collection` default behavior.
  # Changes the default fallback to Joosy.Resource.RESTCollection.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.RESTCollection

  #
  # find(1, parent: foo, from: 'foos', params: {})
  # find('all', parent: foo, from: 'foos', params: {})
  #

  @memberPath: (id, options={}) ->
    path  = @__source || ("/" + @::__entityName.pluralize())
    path += "/#{id}"

    if options.parent instanceof Joosy.Resource.Generic
      path = options.parent.memberPath() + path
    else if options.parent?
      path = options.parent + path

    path += "/#{options.from}" if options.from?
    path

  memberPath: ->
    @constructor.memberPath @id()

  @collectionPath: (options={}) ->
    path  = @__source || ("/" + @::__entityName.pluralize())

    if options.parent instanceof Joosy.Resource.Generic
      path = options.parent.memberPath() + path
    else if options.parent?
      path = options.parent + path

    path += "/#{options.from}" if options.from?
    path

  collectionPath: ->
    @constructor.collectionPath()

  @get: (options, callback) ->
    @__query @collectionPath(options), 'GET', options.params, callback

  @post: (options, callback) ->
    @__query @collectionPath(options), 'POST', options.params, callback

  @put: (options, callback) ->
    @__query @collectionPath(options), 'PUT', options.params, callback

  @delete: (options, callback) ->
    @__query @collectionPath(options), 'DELETE', options.params, callback

  get: (options, callback) ->
    @__query @memberPath(options), 'GET', options.params, callback

  post: (options, callback) ->
    @__query @memberPath(options), 'POST', options.params, callback

  put: (options, callback) ->
    @__query @memberPath(options), 'PUT', options.params, callback

  delete: (options, callback) ->
    @__query @memberPath(options), 'DELETE', options.params, callback

  find: (where, options, callback=nil) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    if where == 'all'
      @constructor.__query @collectionPath(options), 'GET', options.params, (data) =>
        collection = new (@::__collection()) this, options
        collection.load data
        callback(collection)
    else
      @constructor.__query @memberPath(where, options), 'GET', options.params, (data) =>
        resource = @build data
        callback (resource)

  @__query: (path, method, params, callback) ->
    $.ajax url,
      data: params
      type: method
      success: callback
      cache: false
      dataType: 'json'