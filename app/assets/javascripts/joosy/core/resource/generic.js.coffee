class Joosy.Resource.Generic extends Joosy.Module
  @include Joosy.Modules.Log
  @include Joosy.Modules.Events

  @entity: (name) -> @::__entityName = name
  @beforeLoad: (action) -> @::__beforeLoad = action

  @map: (name, klass=false) ->
    klass = window[name.singularize().camelize()] unless klass

    @beforeLoad (data) ->
      @[name] = new Joosy.Resource.GenericCollection(klass)
      @[name].reset data[name] if Object.isArray(data[name])
      data

  @create: ->
    shim = ->
      shim.__call.apply(shim, arguments)

    if shim.__proto__
      shim.__proto__ = @prototype
    else
      for key, value of @prototype
        shim[key] = value
        
    shim.constructor = @
    
    @apply(shim, arguments)

    shim

  @entityName: ->
    unless @::hasOwnProperty '__entityName'
      throw new Error "Resource does not have entity name"

    @::__entityName

  constructor: (data) ->
    @__fillData(data)
    
  get: (path) ->
    target = @__callTarget(path)
    target[0][target[1]]

  set: (path, value) ->
    target = @__callTarget(path)    
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
    @e = @__prepareData(data)

  __prepareData: (data) ->
    data = @__beforeLoad(data) if @__beforeLoad?
    data