#= require ./hash
#= require joosy/modules/resources/model

#
# Resource with REST/JSON backend
#
class Joosy.Resources.REST extends Joosy.Resources.Hash

  @concern Joosy.Modules.Resources.Model

  @registerPlainFilters 'beforeSave'

  @beforeLoad (data) ->
    if data.constructor == Object && Object.keys(data).length == 1 && @__entityName
      name = inflection.camelize(@__entityName, true)
      data = data[name] if data[name]

    data


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
    if args.length == 1 && args[0] instanceof Array
      @__atWrapper(definer, args[0]...)
    else
      definer (clone) =>
        clone.__source = args.reduce (path, arg) ->
          path += if Joosy.Module.hasAncestor arg.constructor, Joosy.Resources.REST
            arg.memberPath()
          else
            arg.replace(/^\/?/, '/')
        , ''
        clone.__source += '/' + inflection.pluralize(@::__entityName)

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
  @at: ->
    @__atWrapper (callback) =>
      # @nodoc
      class Clone extends @
        callback(@)
    , arguments...


  #
  # Creates the proxy of current resource instance binded as a children of given entity
  #
  # @param [Array] args      Array of parent entities. Can be a string or another REST resource.
  #
  # @example Basic usage
  #   Comment.build(1).at('admin', @blog, @post).memberPath() # => '/admin/blogs/555/posts/666/comments/1'
  #
  # @note accepts both array notation (comment.at(['admin', @blog, @post])) and args notation (comment.at('admin', @blog, @post))
  #
  at: (args...) ->
    new (@constructor.at args...) @data

  #
  # Interpolates path with masks by given array of params
  #
  __interpolatePath: (source, ids) ->
    ids = [ids] unless ids instanceof Array
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
    # (options) ->
    if ids.constructor == Object
      options = ids
      ids     = []

    return options.url if options.url

    source = @__source || @constructor.__source

    if source
      path = @__interpolatePath source, ids
    else
      path = '/'

      if @constructor.__namespace__.length > 0
        namespace = @constructor.__namespace__.map (x) -> inflection.underscore(x)
        path += namespace.join('/') + '/'

      path += inflection.pluralize(@__entityName)

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
    if ids.constructor == Object
      options = ids
      ids     = []

    return options.url if options.url

    ids = [ids] unless ids instanceof Array
    id = @id() || ids.pop()

    action = options.action

    ids.push @id()
    path  = @collectionPath(ids, Joosy.Module.merge(options, action: undefined)) + "/#{id}"
    path += "/#{action}" if action?
    path

  #
  # Sends a query using collectionPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [String] method        GET / POST / PUT / DELETE
  # @param [Hash] options         Options to proxy to collectionPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  @send: (method, options, callback) ->
    [options, callback] = @::__extractOptionsAndCallback(options, callback)
    @__query @collectionPath(options), method.toUpperCase(), options.params, callback



  #
  # Sends a query using memberPath.
  # Callback will get parsed JSON object as a parameter.
  #
  # @param [String] method        GET / POST / PUT / DELETE
  # @param [Hash] options         Options to proxy to memberPath
  # @param [Function] callback    Resulting callback
  # @param [Object]   callback    `(error, data) -> ...`
  #
  send: (method, options, callback) ->
    [options, callback] = @__extractOptionsAndCallback(options, callback)
    @constructor.__query @memberPath(options), method.toUpperCase(), options.params, callback

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
  # Requests the required resource from backend
  #
  # @param [String] where         id or an array of ids for interpolated path
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

    result = {}
    result[@::__primaryKey] = if where instanceof Array
      where[where.length-1]
    else
      where

    result = @build result

    # Substitute interpolation mask with actual path
    if where instanceof Array && where.length > 1
      result.__source = @collectionPath where

    @__query @memberPath(where, options), 'GET', options.params, (error, data, xhr) =>
      result.load data if data?
      callback?(error, result, data, xhr)

    result

  #
  # Requests the required collection of resources from backend
  #
  # @param [String] where         id or an array of ids for interpolated path
  # @param [Hash] options         Path modification options
  # @param [Function] callback    `(error, instance, data) -> ...`
  #
  # @option options [String] action             Adds the given string as a last path element
  #   i.e. /resources/trololo
  # @option options [String] url                Sets url for request instead of generated
  #   i.e. /some/custom/url
  # @option options [Hash] params               Passes the given params to the query
  #
  @all: (where, options={}, callback=false) ->
    if typeof(where) == 'function' || where.constructor == Object
      [options, callback] = @::__extractOptionsAndCallback(where, options)
      where = []
    else
      [options, callback] = @::__extractOptionsAndCallback(options, callback)

    result = new @::__collection

    @__query @collectionPath(where, options), 'GET', options.params, (error, rawData, xhr) =>
      if (data = rawData)?
        if data.constructor == Object && !(data = data[inflection.pluralize(@::__entityName)])
          throw new Error "Invalid data for `all` received: #{JSON.stringify(data)}"

        data = data.map (x) =>
          instance = @build x
          # Substitute interpolation mask with actual path
          instance.__source = @collectionPath where if where.length > 1
          instance

        result.load data...

      callback?(error, result, rawData, xhr)

    result

  update: (callback) ->
    @send 'put', {params: @__applyBeforeSaves(@data)}, (error, data) =>
      @load data unless error
      callback? error, @

  create: (callback) ->
    @constructor.send 'post', {params: @__applyBeforeSaves(@data)}, (error, data) =>
      @load data unless error
      callback? error, @

  save: (callback) ->
    if @id()
      @update callback
    else
      @create callback

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

    if typeof(callback) == 'function'
      options.success = (data, _, xhr) -> callback(false, data, xhr)
      options.error   = (xhr) -> callback(xhr)
    else
      Joosy.Module.merge options, callback

    if @::__requestOptions instanceof Function
      @::__requestOptions(options)
    else if @::__requestOptions
      Joosy.Module.merge options, @::__requestOptions

    $.ajax options

  #
  # utility function for better API support for unrequired first options parameter
  #
  __extractOptionsAndCallback: (options, callback) ->
    if typeof(options) == 'function'
      callback = options
      options  = {}
    [options, callback]

# AMD wrapper
if define?.amd?
  define 'joosy/resources/rest', -> Joosy.Resources.REST