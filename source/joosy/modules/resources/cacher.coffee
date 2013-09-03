#= require ../resources

Joosy.Modules.Resources.Cacher =

  included: ->
    @cache   = (cacheKey) -> @::__cacheKey = cacheKey
    @fetcher = (fetcher) -> @::__fetcher = fetcher

    @cached = (callback, cacheKey=false, fetcher=false) ->
      if typeof(cacheKey) == 'function'
        fetcher  = cacheKey
        cacheKey = undefined

      cacheKey ||= @::__cacheKey
      fetcher  ||= @::__fetcher

      if cacheKey && localStorage && localStorage[cacheKey]
        instance = new @ JSON.parse(localStorage[cacheKey])...
        callback? instance
        instance.refresh()
      else
        @fetch (results) =>
          instance = new @ results...
          callback? instance

    @fetch = (callback) ->
      @::__fetcher (results...) =>
        localStorage[@::__cacheKey] = JSON.stringify(results) if @::__cacheKey && localStorage
        callback results

  refresh: (callback) ->
    @constructor.fetch (results) =>
      @load results...
      callback? @

# AMD wrapper
if define?.amd?
  define 'joosy/modules/resources/cacher', -> Joosy.Modules.Resources.Cacher
