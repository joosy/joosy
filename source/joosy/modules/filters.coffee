#= require joosy/joosy

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
  #     @__confirmBeforeLoads() # Runs filters registered as beforeLoad
  #     @__runAfterLoads() # Runs filters registered as afterLoad
  #     @__runAfterUnloads() # Runs filters registered as afterUnload
  #
  included: ->
    @__registerFilterCollector = (filter) ->
      @[filter] = (callback) ->
        unless @::hasOwnProperty "__#{filter}s"
          @::["__#{filter}s"] = [].concat @.__super__["__#{filter}s"] || []
        @::["__#{filter}s"].push callback

      filter.charAt(0).toUpperCase() + filter.slice(1)

    @registerPlainFilters = (filters...) ->
      filters.each (filter) =>
        camelized = @__registerFilterCollector filter

        @::["__run#{camelized}s"] = (params...) ->
          return unless @["__#{filter}s"]

          for callback in @["__#{filter}s"]
            callback = @[callback] unless typeof(callback) == 'function'
            callback.apply(@, params)

        @::["__confirm#{camelized}s"] = (params...) ->
          return true unless @["__#{filter}s"]

          @["__#{filter}s"].reduce (flag, callback) =>
            callback = @[callback] unless typeof(callback) == 'function'
            flag && callback.apply(@, params) != false
          , true

        @::["__apply#{camelized}s"] = (data, params...) ->
          return data unless @["__#{filter}s"]

          for callback in @["__#{filter}s"]
            callback = @[callback] unless typeof(callback) == 'function'
            data = callback.apply(@, [data].concat params)

          data

    @registerSequencedFilters = (filters...) ->
      filters.each (filter) =>
        camelized = @__registerFilterCollector filter

        @::["__run#{camelized}s"] = (params, callback) ->
          return callback() unless @["__#{filter}s"]

          runners  = @["__#{filter}s"]
          filterer = @

          if runners.length == 1
            return runners[0].apply @, params.include(callback)

          Joosy.synchronize (context) ->
            runners.each (runner) ->
              context.do (done) ->
                runner.apply filterer, params.include(done)
            context.after callback

# AMD wrapper
if define?.amd?
  define 'joosy/modules/filters', -> Joosy.Modules.Filters