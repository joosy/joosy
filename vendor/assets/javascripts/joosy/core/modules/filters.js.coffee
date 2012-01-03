Joosy.Modules.Filters =
  included: ->
    @beforeLoad = (callback) ->
      unless @::hasOwnProperty('__beforeLoads')
        @::__beforeLoads = [].concat @.__super__.__beforeLoads || []
      @::__beforeLoads.push callback

    @afterLoad = (callback) ->
      unless @::hasOwnProperty('__afterLoads')
        @::__afterLoads = [].concat @.__super__.__afterLoads || []
      @::__afterLoads.push callback

    @afterUnload = (callback) ->
      unless @::hasOwnProperty('__afterUnloads')
        @::__afterUnloads = [].concat @.__super__.__afterUnloads || []
      @::__afterUnloads.push callback

  __runBeforeLoads: (opts...) ->
    return true if !@__beforeLoads?.length > 0

    flag = true

    @__beforeLoads.each (filter, i) =>
      flag = flag && filter.apply(@, opts)

    return flag

  __runAfterLoads: (opts...) ->
    filter.apply(@, opts) for filter in @__afterLoads if @__afterLoads?

  __runAfterUnloads: (opts...) ->
    filter.apply(@, opts) for filter in @__afterUnloads if @__afterUnloads?