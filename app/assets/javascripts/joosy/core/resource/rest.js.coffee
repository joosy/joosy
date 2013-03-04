#
# Resource with REST/JSON backend
#
class Joosy.Resource.REST extends Joosy.Resource.Generic

  #
  # Implements `@collection` default behavior.
  # Changes the default fallback to Joosy.Resource.RESTCollection.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.RESTCollection

  #
  # Builds parents part of member path based on parents array
  #
  # @param [Array] parents      Array of parents
  #
  # @example Basic usage
  #   Resource.__parentsPath([otherResource, '/bars/1']) # /other_resources/1/bars/1
  #
  @__parentsPath: (parents) ->
    parents.reduce (path, parent) ->
      path += if Joosy.Module.hasAncestor parent.constructor, Joosy.Resource.REST
        parent.memberPath()
      else
        parent
    , ''

  #
  # Builds base path
  #
  # @param [Hash] options       See {Joosy.Resource.REST.find} for possible options
  #
  # @example Basic usage
  #   Resource.basePath() # /resources
  #
  @basePath: (options={}) ->
    if @__source
      path = @__source
    else
      path = '/'
      path += @__namespace__.map((s)-> s.underscore()).join('/') + '/' if @__namespace__.length > 0
      path += @::__entityName.pluralize()

    if options.parent?
      path = @__parentsPath(if Object.isArray(options.parent) then options.parent else [options.parent]) + path

    path

  #
  # Builds base path
  #
  # @see Joosy.Resource.REST.basePath
  #
  basePath: (options={}) ->
    @constructor.basePath options

  #
  # Builds member path based on the given id.
  #
  # @param [String] id          ID of entity to build member path for
  # @param [Hash] options       See {Joosy.Resource.REST.find} for possible options
  #
  # @example Basic usage
  #   Resource.memberPath(1, from: 'foo') # /resources/1/foo
  #
  @memberPath: (id, options={}) ->
    path  = @basePath(options) + "/#{id}"
    path += "/#{options.from}" if options.from?
    path

  #
  # Builds member path
  #
  # @param [Hash] options       See {Joosy.Resource.REST.find} for possible options
  #
  # @example Basic usage
  #   resource.memberPath(from: 'foo') # /resources/1/foo
  #
  memberPath: (options={}) ->
    @constructor.memberPath @id(), options

  #
  # Builds collection path
  #
  # @param [Hash] options       See {Joosy.Resource.REST.find} for possible options
  #
  # @example Basic usage
  #   Resource.collectionPath() # /resources/
  #
  @collectionPath: (options={}) ->
    path = @basePath(options)
    path += "/#{options.from}" if options.from?
    path

  #
  # Builds collection path
  #
  # @see Joosy.Resource.REST.collectionPath
  #
  collectionPath: (options={}) ->
    @constructor.collectionPath options

  #
  # Sends the GET query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  #
  @get: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'GET', options.params, callback

  #
  # Sends the POST query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  #
  @post: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'POST', options.params, callback

  #
  # Sends the PUT query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  #
  @put: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'PUT', options.params, callback

  #
  # Sends the DELETE query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  #
  @delete: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @__query @collectionPath(options), 'DELETE', options.params, callback

  #
  # Sends the GET query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  #
  get: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'GET', options.params, callback

  #
  # Sends the POST query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  #
  post: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'POST', options.params, callback

  #
  # Sends the PUT query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  #
  put: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'PUT', options.params, callback

  #
  # Sends the DELETE query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  #
  delete: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    @constructor.__query @memberPath(options), 'DELETE', options.params, callback

  #
  # Requests the required resources from backend
  #
  # @param [String] where         Possible values: 'all', id.
  #   'all' will query for collection from collectionPath.
  #   Everything else will be considered as an id string and will make resource
  #   query for single instance from memberPath.
  # @param [Hash] options         Path modification options
  # @param [Function] callback    Resulting callback
  #   (will receive retrieved Collection/Resource)
  #
  # @option options [Joosy.Resource.REST] parent            Sets the given resource as a base path
  #   i.e. /parents/1/resources
  # @option options [String] parent                         Sets the given staring as a base path
  #   i.e. /trololo/resources
  # @option options [String] from                           Adds the given string as a last path element
  #   i.e. /resources/trololo
  # @option options [Hash] params                           Passes the given params to the query
  #
  @find: (where, options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    if where == 'all'
      result = new (@::__collection()) this, options

      @__query @collectionPath(options), 'GET', options.params, (data) =>
        result.load data
        callback?(result, data)
    else
      result = @build where
      @__query @memberPath(where, options), 'GET', options.params, (data) =>
        result.load data
        callback?(result, data)

    result

  @__query: (path, method, params, callback) ->
    options =
      data: params
      type: method
      cache: false
      dataType: 'json'

    if Object.isFunction(callback)
      options.success = callback
    else
      Joosy.Module.merge options, callback

    $.ajax path, options

  #
  # Refetches the data from backend and triggers `changed`
  #
  # @param [Hash] options         See {Joosy.Resource.REST.find} for possible options
  # @param [Function] callback    Resulting callback
  #
  reload: (options={}, callback=false) ->
    if Object.isFunction(options)
      callback = options
      options  = {}

    @constructor.__query @memberPath(options), 'GET', options.params, (data) =>
      @load data
      callback? this
