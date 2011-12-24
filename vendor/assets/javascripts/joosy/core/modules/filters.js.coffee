Joosy.Modules.Filters =
  __before_loads: []
  __after_loads: []
  __after_unloads: []

  included: ->
    @before_load = (callback) ->
      unless @::hasOwnProperty('__before_loads')
        @::__before_loads = [].concat @.__super__.__before_loads || []
      @::__before_loads.push callback

    @after_load = (callback) ->
      unless @::hasOwnProperty('__after_loads')
        @::__after_loads = [].concat @.__super__.__after_loads || []
      @::__after_loads.push callback

    @after_unload = (callback) ->
      unless @::hasOwnProperty('__after_unloads')
        @::__after_unloads = [].concat @.__super__.__after_unloads || []
      @::__after_unloads.push callback

  __runBeforeLoads: (opts...) ->
    return true unless @__before_loads.length > 0

    flag = true

    @__before_loads.each (filter, i) =>
      flag = flag && filter.apply(@, opts)

    return flag

  __runAfterLoads: (opts...) ->
    filter.apply(@, opts) for filter in @__after_loads

  __runAfterUnloads: (opts...) ->
    filter.apply(@, opts) for filter in @__after_unloads