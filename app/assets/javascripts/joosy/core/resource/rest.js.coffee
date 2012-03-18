#= require ./rest_collection

#
# Resource with the HTTP REST as the backend.
#
# @example Basic usage
#   class Rocket extends Joosy.Resource.REST
#     @entity 'rocket'
#   
#   r = Rocket.find {speed: 'fast'}   # queries /rockets/?speed=fast to get RESTCollection
#   r = Rocket.find 1                 # queries /rockets/1 to get Rocket instance
#   
#   class Engine extends Joosy.Resource.REST
#     @entity 'engine'
#     @source -> 
#       (rocket) "/rockets/#{rocket 'id'}/engines"
#   
#   e = Engine.at(r).find {oil: true} # queries /rockets/1/engies?oil=true
#
class Joosy.Resource.REST extends Joosy.Resource.Generic

  #
  # Default primary key field 'id'
  #
  __primaryKey: 'id'
  
  #
  # Implements `@collection` default behavior.
  # Changes the default fallback to Joosy.Resource.RESTCollection.
  #
  __collection: ->
    named = @__entityName.camelize().pluralize() + 'Collection'
    if window[named] then window[named] else Joosy.Resource.RESTCollection

  #
  # Sets the field containing primary key.
  #
  # @note It has no direct use inside the REST resource itself and can be omited.
  #   But it usually should not since we have plans on adding some kind of Identity Map to Joosy.
  #
  # @param [String] primary     Name of the field
  #
  @primary: (primary) -> @::__primaryKey = primary

  #
  # Should NOT be called directly, use {Joosy.Resource.Generic.create} instead
  #
  # @param [Integer, String, Object] description    ID of entity or full data to store
  #
  constructor: (description={}) ->
    if @constructor.__isId description
      @id = description
    else
      super description
      @id = @e[@__primaryKey]

  #
  # Queries for REST data and creates resources instances.
  #
  # Returns single entity if integer or string given.
  # Returns collection if no value or Object (with parameters) given.
  #
  # If first parameter is a Function it's considered as a result callback,
  #   in this case parameters will be considered equal to {}
  #
  # @example Different find
  #   class Rocket extends Joosy.Resource.REST
  #     @entity 'rocket'
  #   
  #   Rocket.find 1
  #   Rocket.find {type: 'nuclear'}, (data) -> data
  #   Rocket.find (data) -> data
  #   Rocket.find 1, 
  #     success: (data) -> data)
  #     cache: true
  #
  # @param [Integer, String, Object] description    ID of entity or full data to store
  # @param [Hash, Function] options                 AJAX options.
  #   Will be considered as a success callback if function is given.
  #
  # @return [Joosy.Resource.REST, Joosy.Resource.RESTCollection]
  #
  @find: (description, options) ->
    if Object.isFunction options
      options = {success: options}
    
    if @__isId description
      resource = @create description
      resource.fetch options
      resource
    else
      if !options? && Object.isFunction description
        options = {success: description}
        description = undefined
      resources = new (@::__collection()) this, description
      resources.fetch options
      resources

  #
  # Queries the resource url and reloads the data from server
  #
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
  # @return [Joosy.Resource.REST]
  #
  fetch: (options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success

    @constructor.__ajax 'get', @constructor.__buildSource(extension: @id), options, (e) =>
      @__fillData e, false
      callback? this
      @trigger 'changed'
    this

  save: ->

  #
  # Destroys the resource by DELETE query
  #
  # @param [Hash, Function] options     AJAX options.
  #   Will be considered as a success callback if function is given.
  # @return [Joosy.Resource.REST]
  #
  destroy: (options) ->
    if Object.isFunction options
      callback = options
    else
      callback = options?.success
      delete options?.success
    
    @constructor.__ajax 'delete', @constructor.__buildSource(extension: @id), options, (e) =>
      callback? this
    this
    
  #
  # Requests the REST member URL with POST or any method given in options.type.
  #
  # @param [String] ending              Member url (like 'foo' or 'foo/bar')
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
    
    @constructor.__ajax type, @constructor.__buildSource(extension: "#{@id}/#{ending}"), options, callback

  #
  # Checks if given description can be considered as ID
  #
  # @param [Integer, String, Object] something      Value to test
  # @return [Boolean]
  #
  @__isId: (something) ->
    Object.isNumber(something) || Object.isString(something)

  #
  # jQuery AJAX wrapper.
  #
  # @param [String] method      HTTP Method (GET/POST/PUT/DELETE)
  # @param [String] url         URL to query
  # @param [Hash] options       AJAX options to pass with request
  # @param [Function] callback  XHR callback
  #
  @__ajax: (method, url, options={}, callback) ->
    $.ajax url, Joosy.Module.merge options,
      type: method
      success: callback
      cache: false
      dataType: 'json'

  #
  # Builds URL for current resource location.
  #
  # @param [Hash] options     Handling options
  #
  # @option options [String] extension      String to add to resource base url
  # @option options [Hash] params           GET-params to add to resulting url
  #
  @__buildSource: (options={}) ->
    unless @hasOwnProperty '__source'
      @__source = "/" + @::__entityName.pluralize()
      
    source = if Object.isFunction(@__source) then @__source() else @__source
    source = Joosy.buildUrl "#{source}/#{options.extension || ''}", options.params