#= require ../resources

#
# Cacher allows you to implement the delayed refresh of a resource.
#
# During the first fetch it stores the current value to localStorage
# and on the second call it returns the cached value. At the same moment
# it starts the new fetch and triggers 'changed' event as soon as
# the new value arrives.
#
# When used in conjuction with `@renderDynamic` it allows you to render
# template with cached value immediately. And the new arrived value will
# automatically be injected into DOM.
#
# @example
#   class Test extends Joosy.Resources.Hash
#     @concern Joosy.Modules.Resources.Cacher
#
#     @cache 'test' # key to use at localStorage
#     @fetcher (callback) ->
#       $.get '...', (data) -> callback data
#
#   Test.cached (instance) ->
#     # ...
#
# @mixin
Joosy.Modules.Resources.Cacher =

  ClassMethods:
    #
    # Defines the key that will be used to reference
    # the cached value at localStorage. Unless specified
    # localStorage will not be used.
    #
    # @param [String] cacheKey
    # @example
    #   class Test extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Cacher
    #     @cache 'test'
    #
    cache: (cacheKey) -> @::__cacheKey = cacheKey

    #
    # Defines the asynchronous routine that will be used
    # to load the actual value of resource when `cached` is called.
    #
    # @param [Function<Function>] fetcher
    # @example
    #   class Test extends Joosy.Resources.Hash
    #     @concern Joosy.Modules.Resources.Cacher
    #     @fetcher (callback) ->
    #       $.get '...', (data) -> callback data
    #
    fetcher: (fetcher) -> @::__fetcher = fetcher

    #
    # The main resolver of current value. If the cached
    # value is available it is returned immediately. Otherwise
    # the actual value is loaded.
    #
    # During the first fetch it stores the current value to localStorage
    # and on the second call it returns the cached value. At the same moment
    # it starts the new fetch and triggers 'changed' event as soon as
    # the new value arrives.
    #
    # @param [Function<Cacher>] callback        Action to perform with resulting instance of resource
    # @param [String] cacheKey                  The override for {Joosy.Modules.Resources.Cacher.cache}
    # @param [Function<Function>] fetcher       The override for {Joosy.Modules.Resources.Cacher.fetcher}
    #
    cached: (callback, cacheKey=false, fetcher=false) ->
      if typeof(cacheKey) == 'function'
        fetcher  = cacheKey
        cacheKey = undefined

      cacheKey ||= @::__cacheKey
      fetcher  ||= @::__fetcher

      if cacheKey && localStorage && localStorage[cacheKey]
        instance = @build JSON.parse(localStorage[cacheKey])...
        callback? instance
        instance.refresh()
      else
        @fetch (results) =>
          instance = @build results...
          callback? instance
    #
    # Low-level fetcher that gets the actual value and stores it to
    # localStorage (if required)
    #
    # @param [Function<Mixed>] callback        Action to perform with raw fetched value
    #
    fetch: (callback) ->
      @::__fetcher (results...) =>
        localStorage[@::__cacheKey] = JSON.stringify(results) if @::__cacheKey && localStorage
        callback results

  InstanceMethods:
    #
    # Refreshes the value in both – the cache and the resource itself
    #
    # @param [Function<Cacher>] callback        Action to perform with resulting instance of resource
    #
    refresh: (callback) ->
      @constructor.fetch (results) =>
        @load results...
        callback? @

# AMD wrapper
if define?.amd?
  define 'joosy/modules/resources/cacher', -> Joosy.Modules.Resources.Cacher
