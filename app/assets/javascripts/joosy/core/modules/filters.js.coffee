Joosy.Modules.Filters =
  included: ->
    @beforeLoad = (callback) ->
      unless @::hasOwnProperty '__beforeLoads'
        @::__beforeLoads = [].concat @.__super__.__beforeLoads || []
      @::__beforeLoads.push callback

    @afterLoad = (callback) ->
      unless @::hasOwnProperty '__afterLoads'
        @::__afterLoads = [].concat @.__super__.__afterLoads || []
      @::__afterLoads.push callback

    @afterUnload = (callback) ->
      unless @::hasOwnProperty '__afterUnloads'
        @::__afterUnloads = [].concat @.__super__.__afterUnloads || []
      @::__afterUnloads.push callback

  __runBeforeLoads: (opts...) ->
    unless @__beforeLoads?.length > 0
      return true

    flag = true

    for filter in @__beforeLoads
      unless Object.isFunction filter
        filter = @[filter]
      flag = flag && filter.apply @, opts

    return flag

  __runAfterLoads: (opts...) ->
    if @__afterLoads?.length > 0
      for filter in @__afterLoads
        unless Object.isFunction filter
          filter = @[filter]
        filter.apply @, opts

  __runAfterUnloads: (opts...) ->
    if @__afterUnloads?.length > 0
      for filter in @__afterUnloads
        unless Object.isFunction filter
          filter = @[filter]
        filter.apply @, opts
