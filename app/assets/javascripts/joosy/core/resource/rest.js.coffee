#= require ./rest_collection

#
# Resource with the HTTP REST as the backend
#
# Example:
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
  # Sets the field containing primary key
  #
  # It has no direct use inside the REST resource itself and can be omited
  # That's said: REST resource can work without primary at all. It's here 
  # just to improve end-users experience for cases when primary exists.
  #
  # @param [String] Name of the field
  #
  @primary: (primary) -> @::__primaryKey = primary

  #
  # Should NOT be called directly, use .create() instead
  #
  # @param [Integer|String|Object] ID of entity or full data to store
  #
  constructor: (description={}) ->
    if @constructor.__isId description
      @id = description
    else
      super description
      @id = @e[@__primaryKey]

  #
  # Queries for REST data and creates resources instances
  #
  # Returns single entity if integer or string given
  # Returns collection if no value or Object (with parameters) given
  #
  # If first parameter is a Function it's considered as a result callback
  # In this case parameters will be considered equal to {}
  #
  # Example:
  #   class Rocket extends Joosy.Resource.REST
  #     @entity 'rocket'
  #
  #   Rocket.find 1
  #   Rocket.find {type: 'nuclear'}, (data) -> data
  #   Rocket.find (data) -> data
  #   Rocket.find 1, ((data) -> data), cache: true
  #
  # @param [Integer|String|Object] ID of entity or full data to store
  # @param [Function] `(Resource) -> null` to call when data received
  # @param [Object] Ajax options to pass with request
  # @return [Joosy.Resource.REST|Joosy.Resource.RESTCollection]
  #
  @find: (description, callback, options) ->
    if @__isId description
      resource = @create description
      resource.fetch callback, options
      resource
    else
      if !callback? && Object.isFunction description
        callback = description
        description = undefined
      resources = new Joosy.Resource.RESTCollection this, description
      resources.fetch callback, options
      resources

  #
  # Queries the resource url and reloads the data from server
  #
  # @param [Function] `(Resource) -> null` to call when data received
  # @param [Object] Ajax options to pass with request
  # @return [Joosy.Resource.REST]
  #
  fetch: (callback, options) ->
    @constructor.__ajax 'get', @constructor.__buildSource(extension: @id), options, (e) =>
      @__fillData e, false
      callback? this
      @trigger 'changed'
    this

  save: ->

  #
  # Destroys the resource by DELETE query
  #
  # @param [Function] `(Resource) -> null` to call on complete
  # @param [Object] Ajax options to pass with request
  # @return [Joosy.Resource.REST]
  #
  destroy: (callback, options) ->
    @constructor.__ajax 'delete', @constructor.__buildSource(extension: @id), options, (e) =>
      callback? this
    this

  #
  # Checks if given description can be considered as ID
  #
  # @param [Integer|String|Object] Value to test
  # @return [Boolean]
  #
  @__isId: (something) ->
    Object.isNumber(something) || Object.isString(something)

  #
  # jQuery Ajax wrapper
  #
  # @param [String] HTTP Method (GET/POST/PUT/DELETE)
  # @param [String] URL to query
  # @param [Object] Ajax options to pass with request
  # @param [Function] XHR callback
  #
  @__ajax: (method, url, options={}, callback) ->
    $.ajax url, Joosy.Module.merge options,
      type: method
      success: callback
      cache: false
      dataType: 'json'

  #
  # Builds URL for current resource location
  #
  # @param [Object] Options
  #   extension: string to add to resource base url
  #   params: GET-params to add to resulting url
  #
  @__buildSource: (options={}) ->
    unless @hasOwnProperty '__source'
      @__source = "/" + @::__entityName.pluralize()
    else if Object.isFunction @__source
      throw new Error "#{Joosy.Module.__className @}> should be chained to #{Joosy.Module.__className @}.at()"

    source = Joosy.buildUrl "#{@__source}/#{options.extension || ''}", options.params