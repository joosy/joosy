class Joosy.Resource.Generic extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  # These two (and proxying) have no use at Generic 
  # but will have in any descendant
  @source: (source) -> @__source = source
  @entity: (name) -> @::__entityName = name

  @beforeLoad: (action) -> @::__beforeLoad = action

  @map: (name, klass=false) ->
    unless klass
      klass = window[name.singularize().camelize()]

    @beforeLoad (data) ->
      @[name] = new Joosy.Resource.GenericCollection klass
      if Object.isArray data[name]
        @[name].reset data[name]
      data

  @at: ->
    if !Object.isFunction @__source
      throw new Error "#{Joosy.Module.__className @}> should be created directly (without `at')"
    
    class clone extends this
    clone.__source = @__source arguments...

    clone

  @create: ->
    if Object.isFunction @__source
      throw new Error "#{Joosy.Module.__className @}> should be created through #{Joosy.Module.__className @}.at()"
    
    shim = ->
      shim.__call.apply shim, arguments

    if shim.__proto__
      shim.__proto__ = @prototype
    else
      for key, value of @prototype
        shim[key] = value
        
    shim.constructor = @
    
    @apply shim, arguments

    shim

  @entityName: ->
    unless @::hasOwnProperty '__entityName'
      throw new Error "Resource does not have entity name"

    @::__entityName

  constructor: (data) ->
    @__fillData data
    
  get: (path) ->
    target = @__callTarget path
    target[0][target[1]]

  set: (path, value) ->
    target = @__callTarget path
    target[0][target[1]] = value
    @trigger 'changed'
    null

  __callTarget: (path) ->
    if path.has(/\./) && !@e[path]?
      path    = path.split '.'
      keyword = path.pop()
      target  = @e
      
      for part in path
        target[part] ||= {}
        target = target[part]

      [target, keyword]
    else
      [@e, path]

  __call: (path, value) ->
    if value
      @set path, value
    else
      @get path

  __fillData: (data) ->
    @e = @__prepareData data

  __prepareData: (data) ->
    if Object.isObject(data) && data[@constructor.entityName()] && Object.keys(data).length == 1
      data = data[@constructor.entityName()]
    if @__beforeLoad?
      data = @__beforeLoad data
      
    data
