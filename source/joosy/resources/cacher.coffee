class Joosy.Resources.Cacher extends Joosy.Module

  @include Joosy.Modules.Events
  @include Joosy.Modules.Filters

  @registerPlainFilters 'beforeLoad'

  @cache: (cacheKey) -> @::__cacheKey = cacheKey
  @fetcher: (fetcher) -> @::__fetcher = fetcher

  constructor: (callback, cacheKey=false, fetcher=false) ->
    if typeof(cacheKey) == 'function'
      fetcher  = cacheKey
      cacheKey = undefined

    @__fetcher  = fetcher if fetcher
    @__cacheKey = cacheKey if cacheKey

    if @__cacheKey && localStorage && localStorage[@__cacheKey]
      @data = @__applyBeforeLoads(JSON.parse localStorage[@__cacheKey])
      callback? @
      @refresh()
    else
      @refresh callback

  clone: (callback) ->
    copy = new @constructor(callback, @__cacheKey, @__fetcher)
    copy.data = Object.clone(@data, true)
    copy.trigger 'changed'
    copy

  refresh: (callback) ->
    @__fetcher (result) =>
      localStorage[@__cacheKey] = JSON.stringify(result) if @__cacheKey && localStorage
      @data = @__applyBeforeLoads result
      callback? @
      @trigger 'changed'

# AMD wrapper
if define?.amd?
  define 'joosy/resources/cacher', -> Joosy.Resources.Cacher