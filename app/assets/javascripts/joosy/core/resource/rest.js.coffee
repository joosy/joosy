#= require ./rest_collection

class Joosy.Resource.REST extends Joosy.Resource.Generic

  __primaryKey: 'id'

  @primary: (primary) -> @::__primaryKey = primary

  constructor: (description={}) ->
    if @constructor.__isId description
      @id = description
    else
      super description
      @id = @e[@__primaryKey]

  # Returns single entity if int/string given
  # Returns collection if no value or Object (with parameters) given
  @find: (description, callback, options) ->
    if @__isId description
      resource = @create description
      resource.fetch callback, options
      resource
    else
      if !callback? && Object.isFunction description
        callback = description
        description = undefined
      resources = new Joosy.Resource.RESTCollection @, description
      resources.fetch callback, options
      resources

  fetch: (callback, options) ->
    @constructor.__ajax 'get', @constructor.__buildSource(extension: @id), options, (e) =>
      @__fillData e
      callback? @

    @

  save: ->

  destroy: (callback, options) ->
    @constructor.__ajax 'delete', @constructor.__buildSource(extension: @id), options, (e) =>
      callback? @

    @

  @__isId: (something) ->
    Object.isNumber(something) || Object.isString(something)

  @__ajax: (method, url, options={}, callback) ->
    $.ajax url, Joosy.Module.merge options,
      type: method
      success: callback
      cache: false
      dataType: 'json'

  @__buildSource: (options={}) ->
    unless @hasOwnProperty '__source'
      @__source = "/" + @entityName().pluralize()
    else if Object.isFunction @__source
      throw new Error "#{Joosy.Module.__className @}> should be chained to #{Joosy.Module.__className @}.at()"

    source = Joosy.buildUrl "#{@__source}/#{options.extension || ''}", options.params