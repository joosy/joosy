#= require ./rest_collection

class Joosy.Resource.REST extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  __primary: 'id'
  
  @entity: (name) -> @__entityName = name
  @primary: (primary) -> @::__primary = primary
  @source: (source) -> @__source = source
  @before_load: (action) -> @::__before_load = action

  constructor: (description) ->
    if @__isId(description) 
      @id = description
    else
      @__fillData(description)
      @id = @e[@__primary]

  @entityName: -> @__entityName ?= @name.underscore()

  # Returns single entity if int/string given
  # Returns collection if no value or Object (with parameters) given
  @find: (description, callback) ->
    if Object.isNumber(description) || Object.isString(description)
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
  
  save: ->
    
  destroy: ->

  @__ajax: (method, url, callback) ->
    $.ajax
      method: method
      url: url
      success: callback

  @__buildSource: (options) ->
    @__source ?= "/"+@__getEntityName().pluralize()
    source     = Joosy.buildUrl("#{@__source}/#{options.extension || ''}", options.params)

  __fillData: (data) -> 
    data = Object.extended(data)
    data = @__before_load(data) if @__before_load?
    
    @e = if Object.isObject(data) && data[@constructor.name.underscore()] && data.keys().length == 1
      data[@constructor.name.underscore()]
    else
      data

  __isId: (something) -> Object.isNumber(something) || Object.isString(something)