#
# Filters registration routines
#
# @module
#
Joosy.Modules.Filters =

  #
  # Defines static registration routines
  #
  # @example Set of methods
  #   class Test
  #     @beforeLoad -> # supposed to run before load and control loading queue
  #     @afterLoad -> # supposed to run after load to finalize loading
  #     @afterUnload -> # supposed to run after unload to collect garbage
  #
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

  #
  # Runs filters registered as beforeLoad
  #
  __runBeforeLoads: (opts...) ->
    unless @__beforeLoads?.length > 0
      return true

    flag = true

    for filter in @__beforeLoads
      unless Object.isFunction filter
        filter = @[filter]
      flag = flag && filter.apply @, opts

    return flag

    #
    # Runs filters registered as afterLoad
    #
  __runAfterLoads: (opts...) ->
    if @__afterLoads?.length > 0
      for filter in @__afterLoads
        unless Object.isFunction filter
          filter = @[filter]
        filter.apply @, opts

  #
  # Runs filters registered as afterUnload
  #
  __runAfterUnloads: (opts...) ->
    if @__afterUnloads?.length > 0
      for filter in @__afterUnloads
        unless Object.isFunction filter
          filter = @[filter]
        filter.apply @, opts
