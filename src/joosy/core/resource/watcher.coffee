class Joosy.Resource.Watcher extends Joosy.Module
  @include Joosy.Modules.Events

  @cache: (cacheKey) -> @::__cacheKey = cacheKey
  @fetcher: (fetcher) -> @::__fetcher = fetcher

  @beforeLoad: (action) ->
    unless @::hasOwnProperty '__beforeLoads'
      @::__beforeLoads = [].concat @.__super__.__beforeLoads || []
    @::__beforeLoads.push action

  constructor: (cacheKey=false, fetcher=false) ->
    if Object.isFunction(cacheKey)
      fetcher  = cacheKey
      cacheKey = undefined

    @__fetcher = fetcher if fetcher
    @__cacheKey = cacheKey if cacheKey

  load: (callback) ->
    if @__cacheKey && localStorage[@__cacheKey]
      @data = @prepare(JSON.parse localStorage[@__cacheKey])
      @trigger 'changed'
      @refresh()
      callback? @
    else
      @__fetcher (result) =>
        localStorage[@__cacheKey] = JSON.stringify(result) if @__cacheKey
        @data = @prepare result
        @trigger 'changed'
        callback? @

  clone: ->
    copy = new @constructor(@__cacheKey, @__fetcher)
    copy.data = Object.clone(@data, true)
    copy.trigger 'changed'
    copy

  refresh: (callback) ->
    @__fetcher (result) =>
      localStorage[@__cacheKey] = JSON.stringify(result) if @__cacheKey
      @data = @prepare result
      @trigger 'changed'
      callback? @

  prepare: (data) ->
    if @__beforeLoads?
      data = bl.call(this, data) for bl in @__beforeLoads

    data