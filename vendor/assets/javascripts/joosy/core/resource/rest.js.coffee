#= require ./rest_collection

class Joosy.Resource.REST extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  __primaryKey: 'id'
  
  @entity: (name) -> @__entityName = name
  @primary: (primary) -> @::__primaryKey = primary
  @source: (source) -> @__source = source
  @before_load: (action) -> @::__before_load = action

  constructor: (description) ->
    if @constructor.__isId(description) 
      @id = description
    else
      @__fillData(description)
      @id = @e[@__primaryKey]

  @entityName: -> @__entityName ?= @name.underscore()

  # Returns single entity if int/string given
  # Returns collection if no value or Object (with parameters) given
  @find: (description, callback) ->
    if @__isId(description)
      resource = new @(description)
      resource.fetch callback
      resource
    else
      resources = new Joosy.Resource.RESTCollection(@, description)
      resources.fetch callback
      resources
    
  fetch: (callback) ->
    @constructor.__ajax 'get', @constructor.__buildSource(extension: @id), (e) => 
      @__fillData(e)
      callback?(@)
    @
  
  save: ->
    
  destroy: (callback) ->
    @constructor.__ajax 'delete', @constructor.__buildSource(extension: @id), (e) =>
      callback?(@)
    @

  @__isId: (something) -> Object.isNumber(something) || Object.isString(something)

  @__ajax: (method, url, callback) ->
    $.ajax
      type: method
      url: url
      success: callback

  @__buildSource: (options) ->
    @__source ?= "/"+@entityName().pluralize()
    source     = Joosy.buildUrl("#{@__source}/#{options.extension || ''}", options.params)

  __fillData: (data) -> 
    data = Object.extended(data)
    data = @__before_load(data) if @__before_load?
    
    @e = if Object.isObject(data) && data[@constructor.entityName()] && data.keys().length == 1
      data[@constructor.entityName()]
    else
      data