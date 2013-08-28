#= require ./base
#= require ./rest_collection

#
# Resource with REST/JSON backend
#
class Joosy.Resources.REST extends Joosy.Resources.Base

  @requestOptions: (options) ->
    @::__requestOptions = options

  #
  # Sets default base url for fetching and modifiing resources
  #
  # @note can be omitted if url equals pluralized @entity
  #   i.e. 'comment' entity name => '/comments' url
  #
  # @param [String] primary     Name of the field
  #
  @source: (location) ->
    @__source = location

  #
  # Makes needed changes with clone/wrapper for @at method to extend its' path
  #
  @__atWrapper: (definer, args...) ->
    if args.length == 1 && Object.isArray(args[0])
      @__atWrapper(definer, args[0]...)
    else
      definer (clone) =>
        clone.__source = args.reduce (path, arg) ->
          path += if arg instanceof Joosy.Resources.REST
            arg.memberPath()
          else
            arg.replace(/^\/?/, '/')
        , ''
        clone.__source += '/' + @::__entityName.pluralize()

  #
  # Creates the proxy of current resource binded as a child of given entity
  #
  # @param [Array] args      Array of parent entities. Can be a string or another REST resource.
  #
  # @example Basic usage
  #   Comment.at('admin', @blog, @post).collectionPath() # => '/admin/blogs/555/posts/666/comments'
  #
  # @note accepts both array notation (Comment.at(['admin', @blog, @post])) and args notation (Comment.at('admin', @blog, @post))
  #
  @at: (args...) ->
    @__atWrapper (callback) =>
      class Clone extends @
        callback(@)
    , args...


  #
  # Creates the proxy of current resource instance binded as a child of given entity
  #
  # @param [Array] args      Array of parent entities. Can be a string or another REST resource.
  #
  # @example Basic usage
  #   Comment.build(1).at('admin', @blog, @post).memberPath() # => '/admin/blogs/555/posts/666/comments/1'
  #
  # @note accepts both array notation (comment.at(['admin', @blog, @post])) and args notation (comment.at('admin', @blog, @post))
  #
  at: (args...) ->
    @constructor.__atWrapper (callback) =>
      Object.tap @constructor.__makeShim(@), callback
    , args...

  #
  # Implements `@collection` default behavior.
  # Changes the default fallback to Joosy.Resources.RESTCollection.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resources.RESTCollection


  #
  # Interpolates path with masks by given array of params
  #
  __interpolatePath: (source, ids) ->
    ids = [ids] unless Object.isArray(ids)
    ids.reduce (path, id) ->
      id = id.id() if id instanceof Joosy.Resources.REST
      path.replace /:[^\/]+/, id
    , source

  #
  # Builds collection path
  #
  # @see Joosy.Resources.REST#collectionPath
  #
  @collectionPath: (args...) ->
    @::collectionPath args...

  #
  # Builds collection path
  #
  # @param [Array] ids                Interpolation arguments for nested objects
  # @param [Object] options
  # @option options [String] url      Manually set URL
  # @option options [String] action   Action to add to the URL as a suffix
  #
  # @example Basic usage
  #   Resource.collectionPath() # /resources/
  #
  # @example Nested resources
  #   Resource.collectionPath(['admin', Resource.build 1]) # /admin/resources/1/resources
  #
  collectionPath: (ids=[], options={}) ->
    if Object.isObject(ids)
      options = ids
      ids     = []

    return options.url if options.url

    source = @__source || @constructor.__source

    if source
      path = @__interpolatePath source, ids
    else
      path = '/'
      path += @constructor.__namespace__.map(String::underscore).join('/') + '/' if @constructor.__namespace__.length > 0
      path += @__entityName.pluralize()

    path += "/#{options.action}" if options.action
    path


  #
  # Builds member path based on the given id.
  #
  # @see Joosy.Resources.REST#memberPath
  #
  @memberPath: (args...) ->
    @::memberPath args...

  #
  # Builds member path
  #
  # @param [Array] ids                Interpolation arguments for nested objects
  # @param [Object] options
  # @option options [String] url      Manually set URL
  # @option options [String] action   Action to add to the URL as a suffix
  #
  # @example Basic usage
  #   resource.memberPath(action: 'foo') # /resources/1/foo
  #
  # @example Nested resources
  #   Resource.memberPath(['admin', Resource.build 1]) # /admin/resources/1/resources/2
  #
  memberPath: (ids=[], options={}) ->
    if Object.isObject(ids)
      options = ids
      ids     = []

    return options.url if options.url

    ids = [ids] unless Object.isArray(ids)
    id = @id() || ids.pop()

    action = options.action

    ids.push @id()
    path  = @collectionPath(ids, Object.merge(options, action: undefined)) + "/#{id}"
    path += "/#{action}" if action?
    path

  #
  # Sends the GET query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  @get: (options, callback) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)
    @__query @collectionPath(options), 'GET', options.params, callback

  #
  # Sends the POST query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  @post: (options, callback) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)
    @__query @collectionPath(options), 'POST', options.params, callback

  #
  # Sends the PUT query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  @put: (options, callback) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)
    @__query @collectionPath(options), 'PUT', options.params, callback

  #
  # Sends the DELETE query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  @delete: (options, callback) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)
    @__query @collectionPath(options), 'DELETE', options.params, callback

  #
  # Sends the GET query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  get: (options, callback) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)
    @constructor.__query @memberPath(options), 'GET', options.params, callback

  #
  # Sends the POST query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  post: (options, callback) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)
    @constructor.__query @memberPath(options), 'POST', options.params, callback

  #
  # Sends the PUT query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  put: (options, callback) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)
    @constructor.__query @memberPath(options), 'PUT', options.params, callback

  #
  # Sends the DELETE query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    `(error, data) -> ...`
  #
  delete: (options, callback) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)
    @constructor.__query @memberPath(options), 'DELETE', options.params, callback

  #
  # Requests the required resources from backend
  #
  # @param [String] where         Possible values: 'all', id.
  #   'all' will query for collection from collectionPath.
  #   Everything else will be considered as an id string and will make resource
  #   query for single instance from memberPath.
  # @param [Hash] options         Path modification options
  # @param [Function] callback    `(error, instance, data) -> ...`
  #
  # @option options [String] action             Adds the given string as a last path element
  #   i.e. /resources/trololo
  # @option options [String] url                Sets url for request instead of generated
  #   i.e. /some/custom/url
  # @option options [Hash] params               Passes the given params to the query
  #
  @find: (where, options={}, callback=false) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)

    id = if Object.isArray(where) then where.last() else where

    if id == 'all'
      result = new (@::__collection()) this, options
      path   = @collectionPath where, options
    else
      result = @build id
      path   = @memberPath where, options

    if Object.isArray(where) && where.length > 1
      result.__source = @collectionPath where

    @__query path, 'GET', options.params, (error, data, xhr) =>
      result.load data if data?
      callback?(error, result, data, xhr)

    result

  #
  # Wrapper for AJAX request
  #
  @__query: (path, method, params, callback) ->
    options =
      url: path
      data: params
      type: method
      cache: false
      dataType: 'json'

    if Object.isFunction(callback)
      options.success = (data, _, xhr) -> callback(false, data, xhr)
      options.error   = (xhr) -> callback(xhr)
    else
      Joosy.Module.merge options, callback

    if @::__requestOptions instanceof Function
      @::__requestOptions(options)
    else if @::__requestOptions
      Joosy.Module.merge options, @::__requestOptions
      console.log @::__requestOptions

    $.ajax options

  #
  # Refetches the data from backend and triggers `changed`
  #
  # @param [Hash] options         See {Joosy.Resources.REST.find} for possible options
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, instance, data) -> ...`
  #
  reload: (options={}, callback=false) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)

    @constructor.__query @memberPath(options), 'GET', options.params, (error, data, xhr) =>
      @load data if data?
      callback?(error, @, data, xhr)

  #
  # utility function for better API support for unrequired first options parameter
  #
  __extractOptionsAndCallback: (options, callback) ->
    if Object.isFunction(options)
      callback = options
      options  = {}
    [options, callback]
