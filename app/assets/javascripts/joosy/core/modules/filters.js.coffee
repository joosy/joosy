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
    return true unless @__beforeLoads?.length > 0

    flag = true

    for filter in @__beforeLoads
      filter = @[filter] unless typeof(filter) is 'function'
      flag = flag && filter.apply(@, opts)

    return flag

  __runAfterLoads: (opts...) ->
    if @__afterLoads?
      for filter in @__afterLoads
        filter = @[filter] unless typeof(filter) is 'function'
        filter.apply(@, opts)

  __runAfterUnloads: (opts...) ->
    if @__afterUnloads?
      for filter in @__afterUnloads
        filter = @[filter] unless typeof(filter) is 'function'
        filter.apply(@, opts)