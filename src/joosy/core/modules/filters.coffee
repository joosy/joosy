#= require joosy/core/joosy

#
# Filters registration routines
#
# @mixin
#
Joosy.Modules.Filters =

  #
  # Defines static registration routines
  #
  # @example Set of methods
  #   class Test
  #     @beforeLoad ->  # supposed to run before load and control loading queue
  #     @afterLoad ->   # supposed to run after load to finalize loading
  #     @afterUnload -> # supposed to run after unload to collect garbage
  #
  #     # private
  #
  #     @__runBeforeLoads() # Runs filters registered as beforeLoad
  #     @__runAfterLoads() # Runs filters registered as afterLoad
  #     @__runAfterUnloads() # Runs filters registered as afterUnload
  #
  included: ->
    ['beforeLoad', 'afterLoad', 'afterUnload'].each (filter) =>
      @[filter] = (callback) ->
        unless @::hasOwnProperty "__#{filter}s"
          @::["__#{filter}s"] = [].concat @.__super__["__#{filter}s"] || []
        @::["__#{filter}s"].push callback


['beforeLoad', 'afterLoad', 'afterUnload'].each (filter) =>
  camelized = filter.charAt(0).toUpperCase() + filter.slice(1);

  Joosy.Modules.Filters["__run#{camelized}s"] = (opts...) ->
    return true unless @["__#{filter}s"]

    @["__#{filter}s"].reduce (flag, func) =>
      func = @[func] unless Object.isFunction func
      flag && func.apply(@, opts) != false
    , true

  # AMD wrapper
if define?.amd?
  define 'joosy/modules/filters', -> Joosy.Modules.Filters
