class Joosy.Resource.Watcher extends Joosy.Module
  @include Joosy.Modules.Events

  @cache: (cacheKey) -> @::__cacheKey = cacheKey
  @fetcher: (fetcher) -> @::__fetcher = fetcher

  constructor: (cacheKey=false, fetcher=false) ->
    if Object.isFunction(cacheKey)
      fetcher  = cacheKey
      cacheKey = undefined

    @__fetcher = fetcher if fetcher
    @__cacheKey = cacheKey if cacheKey

  load: (callback) ->
    if @__cacheKey && localStorage[@__cacheKey]
      @data = JSON.parse localStorage[@__cacheKey]
      @trigger 'changed'
      @refresh()
      callback? @
    else
      @__fetcher (result) =>
        localStorage[@__cacheKey] = JSON.stringify(result) if @__cacheKey
        @data = result
        @trigger 'changed'
        callback? @

  clone: ->
    copy = new @constructor(@__cacheKey, @__fetcher)
    copy.data = Object.clone(@data, true)
    copy

  refresh: (callback) ->
    @__fetcher (result) =>
      localStorage[@__cacheKey] = JSON.stringify(result) if @__cacheKey
      @data = result
      @trigger 'changed'
      callback? @