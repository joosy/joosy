class Joosy.Resource.REST extends Joosy.Resource.Generic

  #
  # Implements `@collection` default behavior.
  # Changes the default fallback to Joosy.Resource.RESTCollection.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.RESTCollection

  @memberPath: (id, options={}) ->
    path  = @__source || ("/" + @::__entityName.pluralize())
    path += "/#{id}"

    if options.parent instanceof Joosy.Resource.Generic
      path = options.parent.memberPath() + path
    else if options.parent?
      path = options.parent + path

    path += "/#{options.from}" if options.from?
    path

  memberPath: (options={}) ->
    @constructor.memberPath @id(), options

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
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'GET', options.params, callback

  @post: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'POST', options.params, callback

  @put: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'PUT', options.params, callback

  @delete: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'DELETE', options.params, callback

  get: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'GET', options.params, callback

  post: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'POST', options.params, callback

  put: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'PUT', options.params, callback

  delete: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'DELETE', options.params, callback

  @find: (where, options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    if where == 'all'
      result = new (@::__collection()) this, options

      @__query @collectionPath(options), 'GET', options.params, (data) =>
        result.load data
        callback?(result)
    else
      result = @build()
      @__query @memberPath(where, options), 'GET', options.params, (data) =>
        result.load data
        callback?(result)

    result

  @__query: (path, method, params, callback) ->
    $.ajax path,
      data: params
      type: method
      success: callback
      cache: false
      dataType: 'json'

  reload: (options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @constructor.__query @memberPath(options), 'GET', options.params, (data) =>
      @load data
      callback? this